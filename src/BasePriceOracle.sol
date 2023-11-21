// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

//  __  /   _ \  _ \   _ \     _ \ _ \   _ \ __ __| _ \   __|   _ \  |
//     /   (   |   /  (   |    __/   /  (   |   |  (   | (     (   | |
//  ____| \___/ _|_\ \___/    _|  _|_\ \___/   _| \___/ \___| \___/ ____|

import {AccessControlDefaultAdminRules as AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControlDefaultAdminRules.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IFeedRegistry, Feed} from "src/IFeedRegistry.sol";
import {IPriceSubscriber} from "src/IPriceSubscriber.sol";
import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {CToken, PriceOracle as IPriceOracle} from "lib/zoro-protocol/contracts/PriceOracle.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/**
 * @author Zoro
 * @notice Prices are published to the oracle from Chainlink data feeds
 * @notice Prices are consumed from the oracle by `Comptroller` contracts
 * @notice Feeds must be configured before prices can be published
 * @notice A `CToken` must be connected to a feed before prices can be consumed
 */
contract BasePriceOracle is
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
    mapping(AggregatorV3Interface => Feed) public allFeeds;
    mapping(CToken => AggregatorV3Interface) public connectedFeeds;

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

    error PriceIsZero();
    error InvalidAddress();
    error FeedNotConfigured(AggregatorV3Interface feed);
    error PriceNotSet(CToken cToken);

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
     * @notice Publish the price from a feed
     * @notice Reverts if the new price is invalid
     * @notice Reverts if the feed is not configured with `configureFeed`
     * @param feed Chainlink data feed https://data.chain.link/
     * @param price `latestAnswer` from `feed` without any decimal conversion
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
     * @notice Configure the settings for a price feed
     * @notice A feed must be configured before it can have prices published
     * @notice A feed must be configured before a `CToken` can be connected
     * @param feed Chainlink data feed https://data.chain.link/
     */
    function configureFeed(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external onlyRole(FEED_ADMIN_ROLE) nonReentrant {
        _configureFeed(feed, decimals, underlyingDecimals);

        emit UpdateFeed(feed, decimals, underlyingDecimals);
    }

    /**
     * @notice Use prices from `feed` for the `cToken` underlying asset
     * @notice Reverts if the feed is not configured with `configureFeed`
     * @dev Feeds and `CToken` contracts have a one-to-many relationship
     * @param cToken Compound market that needs prices from the `feed`
     * @param feed Chainlink data feed https://data.chain.link/
     */
    function connectCTokenToFeed(CToken cToken, AggregatorV3Interface feed)
        external
        onlyRole(FEED_ADMIN_ROLE)
        nonReentrant
    {
        _connectCTokenToFeed(cToken, feed);

        emit UpdateCTokenFeed(cToken, feed);
    }

    /**
     * @notice Get the price for the underlying asset of a `CToken`
     * @notice Prices are used by `Comptroller` contracts
     * @notice Prices are automatically converted to the correct decimals
     * @notice Reverts if the price is invalid
     * @notice Reverts if `cToken` is not connected with `connectCTokenToFeed`
     * @notice Reverts if the feed is not configured with `configureFeed`
     * @dev `Comptroller` expects the format: `${raw price} * 1e36 / baseUnit`
     * @param cToken Compound market
     * @return Price with the correct decimals expected by a `Comptroller`
     */
    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {
        Feed memory fd = _getConnectedFeed(cToken);

        uint256 feedPrice = _prices[fd.feed];
        if (feedPrice == 0) revert PriceNotSet(cToken);

        uint256 priceMantissa = _convertDecimalsForComptroller(
            feedPrice,
            fd.decimals,
            fd.underlyingDecimals
        );

        return priceMantissa;
    }

    /**
     * @notice Get all configured feed addresses
     */
    function getFeedAddresses() external view returns (address[] memory) {
        return _feedAddresses.values();
    }

    function _setUnderlyingPrice(AggregatorV3Interface feed, uint256 price)
        internal
    {
        _validateAddress(address(feed));
        _validateFeed(allFeeds[feed], feed);
        _validatePrice(price);

        _prices[feed] = price;
    }

    function _configureFeed(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) internal returns (bool) {
        _validateAddress(address(feed));

        allFeeds[feed] = Feed(feed, decimals, underlyingDecimals);
        return _feedAddresses.add(address(feed));
    }

    function _connectCTokenToFeed(CToken cToken, AggregatorV3Interface feed)
        internal
    {
        _validateAddress(address(cToken));
        _validateAddress(address(feed));
        _validateFeed(allFeeds[feed], feed);

        connectedFeeds[cToken] = feed;
    }

    function _getConnectedFeed(CToken cToken)
        internal
        view
        returns (Feed memory)
    {
        _validateAddress(address(cToken));
        AggregatorV3Interface feed = connectedFeeds[cToken];

        _validateAddress(address(feed));

        Feed storage fd = allFeeds[feed];
        _validateFeed(fd, feed);

        return fd;
    }

    /**
     * @notice Comptroller expects the format: `${raw price} * 1e36 / baseUnit`
     * @notice The `baseUnit` is the smallest whole unit of the asset
     * @notice E.g. The `baseUnit` of ETH is 1e18
     * @notice E.g. The ETH Chainlink data feed uses 8 decimal prices
     * @notice E.g. `${ETH price} = ${ETH raw price} * 1e(36 - 8) / 1e18`
     * @dev Zero is a valid value for `decimals` and `underlyingDecimals`
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

        // Handle decimal combinations that round `value` to zero
        if (decimalDelta > _MAX_UINT_DIGITS) return 0;

        // All remaining decimal combinations will not cause an overflow
        uint256 decimalDeltaBase = 10**decimalDelta;

        // This operation should never overflow because of the conditional
        uint256 normalizedValue = totalDecimals < PRICE_MANTISSA_DECIMALS
            ? value * decimalDeltaBase
            : value / decimalDeltaBase;

        return normalizedValue;
    }

    function _validateAddress(address addr) internal pure {
        if (address(addr) == address(0)) revert InvalidAddress();
    }

    function _validateFeed(Feed memory fd, AggregatorV3Interface feed)
        internal
        pure
    {
        bool noConfig = address(fd.feed) == address(0);
        bool incorrectConfig = fd.feed != feed;
        if (noConfig || incorrectConfig) revert FeedNotConfigured(feed);
    }

    function _validatePrice(uint256 price) internal pure {
        if (price == 0) revert PriceIsZero();
    }
}
