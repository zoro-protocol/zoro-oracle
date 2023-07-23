// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {AccessControlDefaultAdminRules as AccessControl} from "openzeppelin/contracts/access/AccessControlDefaultAdminRules.sol";
import {ReentrancyGuard} from "openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Math} from "openzeppelin/contracts/utils/math/Math.sol";
import {CToken, PriceOracle as IPriceOracle} from "zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";
import {IFeedRegistry, FeedData, MAX_DELTA_BASE, DEFAULT_MAX_DELTA_MANTISSA, DEFAULT_LIVE_PERIOD} from "/IFeedRegistry.sol";
import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";

error InvalidTimestamp(uint256 timestamp);
error PriceIsZero();
error PriceIsStale(uint256 timestamp);
error InvalidAddress();
error FeedNotConfigured(AggregatorV3Interface feed);
error PriceNotSet(CToken cToken);

contract PriceOracle is
    IFeedRegistry,
    IPriceReceiver,
    IPriceOracle,
    ReentrancyGuard,
    AccessControl
{
    using Math for uint256;

    bytes32 public constant PRICE_PUBLISHER_ROLE =
        keccak256("PRICE_PUBLISHER_ROLE");
    bytes32 public constant FEED_ADMIN_ROLE = keccak256("FEED_ADMIN_ROLE");

    // `public` so the configuration can be checked
    mapping(AggregatorV3Interface => FeedData) public feedData;

    // `internal` so all integrations must access through `getUnderlyingPrice`
    mapping(CToken => PriceData) internal _priceData;

    event NewPrice(
        AggregatorV3Interface feed,
        uint256 price,
        uint256 timestamp
    );

    event UpdateFeed(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    );

    event PriceExceededDelta(uint256 oldPrice, uint256 price, uint256 newPrice);

    /**
     * @param pricePublisher Account that publishes new prices from Chainlink
     * @param feedAdmin Account that manages settings for each price feed
     * @param defaultAdmin Account that can grant and revoke all roles
     */
    constructor(
        address pricePublisher,
        address feedAdmin,
        address defaultAdmin
    ) AccessControl(6 hours, defaultAdmin) {
        _grantRole(PRICE_PUBLISHER_ROLE, pricePublisher);
        _grantRole(FEED_ADMIN_ROLE, feedAdmin);
    }

    /**
     * @notice Set the underlying price of the CToken mapped to the `feed`
     * @notice CTokens are mapped to a `feed` with `setFeedData`
     * @notice Caller can set prices pulled from a price feed with no knowledge
     * of protocol implementation.
     */
    function setUnderlyingPrice(
        AggregatorV3Interface feed,
        uint256 price,
        uint256 timestamp
    ) external onlyRole(PRICE_PUBLISHER_ROLE) nonReentrant {
        _validateAddress(address(feed));

        (PriceData memory oldPd, FeedData memory fd) = _getData(feed);

        _validateTimestamp(oldPd, timestamp);
        _validatePrice(price);

        uint256 newPrice = _sanitizePrice(oldPd, fd, price);

        _priceData[fd.cToken] = PriceData(feed, newPrice, timestamp);

        emit NewPrice(feed, newPrice, timestamp);
    }

    /**
     * @notice Map a CToken to a price feed and configure the feed
     * @notice Set `livePeriod` or `maxDeltaMantissa` to zero for default values
     * @notice Must be called before prices can be set with `setUnderlyingPrice`
     * @notice `feed` is an L1 price feed and `cToken` is an L2 CToken
     */
    function setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external onlyRole(FEED_ADMIN_ROLE) nonReentrant {
        _validateAddress(address(feed));
        _validateAddress(address(cToken));

        feedData[feed] = FeedData(cToken, livePeriod, maxDeltaMantissa);

        emit UpdateFeed(feed, cToken, livePeriod, maxDeltaMantissa);
    }

    /**
     * @notice Get the underlying price of a CToken
     * @notice Reverts if there is no feed, no price, or stale price data
     */
    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {
        (PriceData memory pd, FeedData memory fd) = _getData(cToken);

        _validateLiveness(fd, pd.timestamp);

        return pd.price;
    }

    function _sanitizePrice(
        PriceData memory pd,
        FeedData memory fd,
        uint256 price
    ) internal returns (uint256) {
        uint256 oldPrice = pd.price;

        // Do not enforce max delta if price is zero, occurs on first update
        if (oldPrice == 0) {
            return price;
        }

        uint256 deltaMantissa = _calculateDeltaMantissa(oldPrice, price);

        uint256 maxDeltaMantissa = _useDefault(
            fd.maxDeltaMantissa,
            DEFAULT_MAX_DELTA_MANTISSA
        );

        uint256 newPrice = 0;

        if (deltaMantissa <= maxDeltaMantissa) newPrice = price;
        else {
            bool deltaIsNegative = price < oldPrice;

            newPrice = _calculateNewPriceFromDelta(
                oldPrice,
                maxDeltaMantissa,
                deltaIsNegative
            );

            emit PriceExceededDelta(oldPrice, price, newPrice);
        }

        return newPrice;
    }

    function _getData(CToken cToken)
        internal
        view
        returns (PriceData memory, FeedData memory)
    {
        PriceData memory pd = _safeGetPriceData(cToken);
        FeedData storage fd = feedData[pd.feed];

        return (pd, fd);
    }

    function _getData(AggregatorV3Interface feed)
        internal
        view
        returns (PriceData memory, FeedData memory)
    {
        FeedData memory fd = _safeGetFeedData(feed);
        PriceData storage pd = _priceData[fd.cToken];

        return (pd, fd);
    }

    function _validateLiveness(FeedData memory fd, uint256 timestamp)
        internal
        view
    {
        uint256 livePeriod = _useDefault(fd.livePeriod, DEFAULT_LIVE_PERIOD);

        if (timestamp + livePeriod < block.timestamp)
            revert PriceIsStale(timestamp);
    }

    function _safeGetFeedData(AggregatorV3Interface feed)
        internal
        view
        returns (FeedData memory)
    {
        FeedData storage fd = feedData[feed];

        if (address(fd.cToken) == address(0)) revert FeedNotConfigured(feed);

        return fd;
    }

    function _safeGetPriceData(CToken cToken)
        internal
        view
        returns (PriceData memory)
    {
        PriceData storage pd = _priceData[cToken];

        bool feedNotSet = address(pd.feed) == address(0);
        bool priceNotSet = pd.price == 0;

        if (feedNotSet || priceNotSet) revert PriceNotSet(cToken);

        return pd;
    }

    function _validateAddress(address addr) internal pure {
        if (address(addr) == address(0)) revert InvalidAddress();
    }

    function _validateTimestamp(PriceData memory pd, uint256 timestamp)
        internal
        pure
    {
        if (timestamp < pd.timestamp) revert InvalidTimestamp(timestamp);
    }

    function _validatePrice(uint256 price) internal pure {
        if (price == 0) revert PriceIsZero();
    }

    function _calculateNewPriceFromDelta(
        uint256 oldPrice,
        uint256 deltaMantissa,
        bool deltaIsNegative
    ) internal pure returns (uint256) {
        uint256 newPriceDelta = oldPrice.mulDiv(deltaMantissa, MAX_DELTA_BASE);

        uint256 newPrice = deltaIsNegative
            ? oldPrice - newPriceDelta
            : oldPrice + newPriceDelta;

        return newPrice;
    }

    function _calculateDeltaMantissa(uint256 oldPrice, uint256 newPrice)
        internal
        pure
        returns (uint256)
    {
        uint256 delta = newPrice.max(oldPrice) - newPrice.min(oldPrice);

        return delta > 0 ? delta.mulDiv(MAX_DELTA_BASE, oldPrice) : 0;
    }

    function _useDefault(uint256 value, uint256 defaultValue)
        internal
        pure
        returns (uint256)
    {
        return value > 0 ? value : defaultValue;
    }
}
