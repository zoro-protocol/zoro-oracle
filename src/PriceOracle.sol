// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {AccessControlDefaultAdminRules as AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControlDefaultAdminRules.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFeedRegistry, FeedData} from "src/IFeedRegistry.sol";
import {IPriceSubscriber, PriceData} from "src/IPriceSubscriber.sol";
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
    EnumerableSet.AddressSet internal feedAddresses;

    // `internal` so all integrations must access through `getUnderlyingPrice`
    mapping(CToken => PriceData) internal _priceData;

    event NewPrice(AggregatorV3Interface indexed feed, uint256 price);
    event UpdateFeed(AggregatorV3Interface indexed feed, CToken indexed cToken);

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
        FeedData memory fd = _safeGetFeedData(feed);

        _setUnderlyingPrice(feed, fd, price);

        emit NewPrice(feed, price);
    }

    /**
     * @notice Map a CToken to a price feed and configure the feed
     * @notice Must be called before prices can be set with `setUnderlyingPrice`
     * @notice `feed` is an L1 price feed and `cToken` is an L2 CToken
     */
    function setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external onlyRole(FEED_ADMIN_ROLE) nonReentrant {
        _setFeedData(feed, cToken, decimals, underlyingDecimals);
        feedAddresses.add(address(feed));

        emit UpdateFeed(feed, cToken);
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

        uint256 priceMantissa = _convertDecimalsForComptroller(
            pd.price,
            fd.decimals,
            fd.underlyingDecimals
        );

        return priceMantissa;
    }

    function getFeedAddresses() external view returns (address[] memory) {
        return feedAddresses.values();
    }

    function _setUnderlyingPrice(
        AggregatorV3Interface feed,
        FeedData memory fd,
        uint256 price
    ) internal {
        _validateAddress(address(feed));
        _validatePrice(price);

        _priceData[fd.cToken] = PriceData(feed, price);
    }

    function _setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 decimals,
        uint256 underlyingDecimals
    ) internal {
        _validateAddress(address(feed));
        _validateAddress(address(cToken));

        feedData[feed] = FeedData(cToken, decimals, underlyingDecimals);
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
