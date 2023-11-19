// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

import {AccessControlDefaultAdminRules as AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControlDefaultAdminRules.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFeedRegistry, FeedData} from "src/IFeedRegistry.sol";
import {IPriceSubscriber} from "src/IPriceSubscriber.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {CToken, PriceOracle as IPriceOracle} from "lib/zoro-protocol/contracts/PriceOracle.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

error PriceIsZero();
error InvalidAddress();
error FeedNotConfigured(AggregatorV3Interface feed);
error PriceNotSet(CToken cToken);

contract PriceOracle is
    IPriceSubscriber,
    IFeedRegistry,
    IPriceOracle,
    ReentrancyGuard,
    AccessControl
{
    using Math for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant PRICE_PUBLISHER_ROLE =
        keccak256("PRICE_PUBLISHER_ROLE");
    bytes32 public constant FEED_ADMIN_ROLE = keccak256("FEED_ADMIN_ROLE");

    // Comptroller needs prices in the format: ${raw price} * 1e36 / baseUnit
    uint256 public constant PRICE_MANTISSA_DECIMALS = 36;
    uint256 private constant _MAX_UINT_DIGITS = 77;

    // `public` so the configuration can be checked
    mapping(AggregatorV3Interface => FeedData) public feedData;
    mapping(CToken => AggregatorV3Interface) public cTokenFeeds;

    EnumerableSet.AddressSet internal _feedAddresses;

    // `internal` so all integrations must access through `getUnderlyingPrice`
    mapping(AggregatorV3Interface => uint256) internal _prices;

    event NewPrice(AggregatorV3Interface indexed feed, uint256 price);
    event UpdateFeed(
        AggregatorV3Interface indexed feed,
        uint256 decimals,
        uint256 underlyingDecimals
    );
    event UpdateCTokenFeed(
        CToken indexed cToken,
        AggregatorV3Interface indexed feed
    );

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
    function setUnderlyingPrice(AggregatorV3Interface feed, uint256 price)
        external
        onlyRole(PRICE_PUBLISHER_ROLE)
        nonReentrant
    {
        _setUnderlyingPrice(feed, price);

        emit NewPrice(feed, price);
    }

    /**
     * @notice Map a CToken to a price feed and configure the feed
     * @notice Must be called before prices can be set with `setUnderlyingPrice`
     * @notice `feed` is an L1 price feed
     */
    function setFeedData(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external onlyRole(FEED_ADMIN_ROLE) nonReentrant {
        _setFeedData(feed, decimals, underlyingDecimals);

        emit UpdateFeed(feed, decimals, underlyingDecimals);
    }

    /**
     * @notice Set the price feed used by a CToken
     * @notice `feed` is an L1 price feed and `cToken` is an L2 CToken
     * @dev Creates a one-to-many mapping of price feeds to CTokens
     */
    function setCTokenFeed(CToken cToken, AggregatorV3Interface feed)
        external
        onlyRole(FEED_ADMIN_ROLE)
        nonReentrant
    {
        _setCTokenFeed(cToken, feed);

        emit UpdateCTokenFeed(cToken, feed);
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
        FeedData memory fd = _getFeedData(cToken);

        uint256 feedPrice = _prices[fd.feed];
        if (feedPrice == 0) revert PriceNotSet(cToken);

        uint256 priceMantissa = _convertDecimalsForComptroller(
            feedPrice,
            fd.decimals,
            fd.underlyingDecimals
        );

        return priceMantissa;
    }

    function getFeedAddresses() external view returns (address[] memory) {
        return _feedAddresses.values();
    }

    function _setUnderlyingPrice(AggregatorV3Interface feed, uint256 price)
        internal
    {
        _validateAddress(address(feed));
        _validatePrice(price);

        _prices[feed] = price;
    }

    function _setFeedData(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) internal {
        _validateAddress(address(feed));

        feedData[feed] = FeedData(feed, decimals, underlyingDecimals);
        _feedAddresses.add(address(feed));
    }

    function _setCTokenFeed(CToken cToken, AggregatorV3Interface feed)
        internal
    {
        _validateAddress(address(feed));
        _validateAddress(address(cToken));

        cTokenFeeds[cToken] = feed;
    }

    function _getFeedData(CToken cToken)
        internal
        view
        returns (FeedData memory)
    {
        _validateAddress(address(cToken));
        AggregatorV3Interface feed = cTokenFeeds[cToken];

        _validateAddress(address(feed));
        FeedData storage fd = feedData[feed];

        if (address(fd.feed) == address(0)) revert FeedNotConfigured(feed);

        return fd;
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

    function _validateAddress(address addr) internal pure {
        if (address(addr) == address(0)) revert InvalidAddress();
    }

    function _validatePrice(uint256 price) internal pure {
        if (price == 0) revert PriceIsZero();
    }
}
