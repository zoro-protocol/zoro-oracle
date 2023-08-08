// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {AccessControlDefaultAdminRules as AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControlDefaultAdminRules.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {CToken, PriceOracle as IPriceOracle} from "lib/zoro-protocol/contracts/PriceOracle.sol";
import {IPriceSubscriber, PriceData} from "src/IPriceSubscriberExpanded.sol";
import {IFeedRegistry, FeedData, MAX_DELTA_BASE, DEFAULT_MAX_DELTA_MANTISSA, DEFAULT_LIVE_PERIOD} from "src/IFeedRegistryExpanded.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error InvalidTimestamp(uint256 timestamp);
error PriceIsZero();
error PriceIsStale(uint256 timestamp);
error InvalidAddress();
error FeedNotConfigured(AggregatorV3Interface feed);
error PriceNotSet(CToken cToken);

contract AnchoredPriceOracle is
    IFeedRegistry,
    IPriceSubscriber,
    IPriceOracle,
    ReentrancyGuard,
    AccessControl
{
    using Math for uint256;

    bytes32 public constant PRICE_PUBLISHER_ROLE =
        keccak256("PRICE_PUBLISHER_ROLE");
    bytes32 public constant FEED_ADMIN_ROLE = keccak256("FEED_ADMIN_ROLE");

    // Comptroller needs prices in the format: ${raw price} * 1e36 / baseUnit
    uint256 public constant PRICE_MANTISSA_DECIMALS = 36;
    uint256 private constant _MAX_UINT_DIGITS = 77;

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
        uint256 decimals,
        uint256 underlyingDecimals,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external onlyRole(FEED_ADMIN_ROLE) nonReentrant {
        _validateAddress(address(feed));
        _validateAddress(address(cToken));

        feedData[feed] = FeedData(
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );

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

        uint256 priceMantissa = _convertDecimalsForComptroller(
            pd.price,
            fd.decimals,
            fd.underlyingDecimals
        );

        return priceMantissa;
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

        uint256 newPrice = _applyPriceLimits(
            price,
            oldPrice,
            fd.maxDeltaMantissa
        );

        // If the price was modified, it has exceeded the max delta
        if (newPrice != price) {
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

    // TODO: If an extremely large timestamp is passed, it could lock all future prices
    function _validateTimestamp(PriceData memory pd, uint256 timestamp)
        internal
        pure
    {
        if (timestamp < pd.timestamp) revert InvalidTimestamp(timestamp);
    }

    function _validatePrice(uint256 price) internal pure {
        if (price == 0) revert PriceIsZero();
    }

    /**
     * @notice No limits are applied if `oldPrice` is invalid. The new price
     * should not be limited by an invalid anchor price.
     */
    function _applyPriceLimits(
        uint256 price,
        uint256 oldPrice,
        uint256 maxDeltaMantissa
    ) internal pure returns (uint256) {
        uint256 deltaMantissa = _calculateDeltaMantissa(oldPrice, price);

        uint256 maxDeltaMantissa_ = _useDefault(
            maxDeltaMantissa,
            DEFAULT_MAX_DELTA_MANTISSA
        );

        uint256 newPrice = _updatePriceWithMaxDelta(
            price,
            oldPrice,
            deltaMantissa,
            maxDeltaMantissa_
        );

        return newPrice;
    }

    /**
     * @notice The max delta is infinite if `oldPrice` is invalid. The new
     * price should not be limited by an invalid anchor price.
     */
    function _updatePriceWithMaxDelta(
        uint256 price,
        uint256 oldPrice,
        uint256 deltaMantissa,
        uint256 maxDeltaMantissa
    ) internal pure returns (uint256) {
        uint256 newPrice = 0;

        if (deltaMantissa <= maxDeltaMantissa) newPrice = price;
        else {
            bool deltaIsNegative = price < oldPrice;

            newPrice = _updatePriceWithDelta(
                oldPrice,
                maxDeltaMantissa,
                deltaIsNegative
            );
        }

        return newPrice;
    }

    function _updatePriceWithDelta(
        uint256 oldPrice,
        uint256 deltaMantissa,
        bool deltaIsNegative
    ) internal pure returns (uint256) {
        uint256 newPriceDelta = _mulDivCapped(
            oldPrice,
            deltaMantissa,
            MAX_DELTA_BASE
        );

        uint256 newPrice = 0;

        if (deltaIsNegative) {
            // Limit the price to zero instead of underflow
            newPrice = oldPrice > newPriceDelta ? oldPrice - newPriceDelta : 0;
        } else {
            // Limit the price to max uint instead of overflow
            newPrice = oldPrice < type(uint256).max - newPriceDelta
                ? oldPrice + newPriceDelta
                : type(uint256).max;
        }

        return newPrice;
    }

    /**
     * @notice Return zero if `oldPrice` is invalid. The new price should not
     * be limited by an invalid anchor price.
     *
     * @notice Return uint256 max if `abs(newPrice - oldPrice) / oldPrice` is
     * greater than `type(uint256).max / MAX_DELTA_BASE` to prevent overflow.
     *
     * @notice Return zero if delta is less than `oldPrice / MAX_DELTA_BASE`.
     * This condition occurs because of `uint256` truncation.
     */
    function _calculateDeltaMantissa(uint256 oldPrice, uint256 newPrice)
        internal
        pure
        returns (uint256)
    {
        if (oldPrice == 0) return 0;

        uint256 delta = newPrice.max(oldPrice) - newPrice.min(oldPrice);

        uint256 deltaMantissa = _mulDivCapped(delta, MAX_DELTA_BASE, oldPrice);

        return deltaMantissa;
    }

    /**
     * @notice Comptroller expects the format: `${raw price} * 1e36 / baseUnit`
     * The `baseUnit` of an asset is the smallest whole unit of that asset.
     * E.g. The `baseUnit` of ETH is 1e18 and the price feed is 8 decimals:
     * `price * 1e(36 - 8)/baseUnit`
     *
     * @dev There are no default values for `decimals` and `underlyingDecimals`
     * because zero is a valid value.
     */
    function _convertDecimalsForComptroller(
        uint256 value,
        uint256 decimals,
        uint256 underlyingDecimals
    ) internal pure returns (uint256) {
        // Net out all decimals before scaling to maximize precision
        uint256 totalDecimals = decimals + underlyingDecimals;
        uint256 decimalDelta = totalDecimals.max(PRICE_MANTISSA_DECIMALS) -
            totalDecimals.min(PRICE_MANTISSA_DECIMALS);

        // Handle decimals that normalize all possible `uint` values to zero
        if (decimalDelta > _MAX_UINT_DIGITS) return 0;

        // Remaining decimal values will not cause an overflow
        uint256 decimalDeltaBase = 10**decimalDelta;

        // Will not overflow if condition for multiplication is held
        uint256 normalizedValue = totalDecimals < PRICE_MANTISSA_DECIMALS
            ? value * decimalDeltaBase
            : value / decimalDeltaBase;

        return normalizedValue;
    }

    function _useDefault(uint256 value, uint256 defaultValue)
        internal
        pure
        returns (uint256)
    {
        return value > 0 ? value : defaultValue;
    }

    /**
     * @notice If `Math.mulDiv` would overflow, instead return `uint256` max
     */
    function _mulDivCapped(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        if (y == 0) return 0;
        else if (x / z >= type(uint256).max / y) return type(uint256).max;
        else return x.mulDiv(y, z);
    }
}
