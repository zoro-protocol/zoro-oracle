// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

import {AggregatorV3Interface, CToken, EnumerableSet, Feed, BasePriceOracle} from "src/BasePriceOracle.sol";

contract PriceOracleHarness is BasePriceOracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        address pricePublisher,
        address feedAdmin,
        address defaultAdmin
    ) BasePriceOracle(pricePublisher, feedAdmin, defaultAdmin) {}

    function workaround_setAllFeeds(
        AggregatorV3Interface feed,
        Feed calldata fd
    ) external {
        allFeeds[feed] = fd;
    }

    function workaround_setConnectedFeeds(
        CToken cToken,
        AggregatorV3Interface feed
    ) external {
        connectedFeeds[cToken] = feed;
    }

    function workaround_setFeedAddress(address feed) external {
        _feedAddresses.add(feed);
    }

    function workaround_setPrice(AggregatorV3Interface feed, uint256 price)
        external
    {
        feedPrices[feed] = price;
    }

    function exposed_configureFeed(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external {
        _configureFeed(feed, decimals, underlyingDecimals);
    }

    function exposed_connectCTokenToFeed(
        CToken cToken,
        AggregatorV3Interface feed
    ) external {
        _connectCTokenToFeed(cToken, feed);
    }

    function exposed_setFeedPrice(AggregatorV3Interface feed, uint256 price)
        external
    {
        _setFeedPrice(feed, price);
    }

    function exposed_getConnectedFeed(CToken cToken)
        external
        view
        returns (Feed memory)
    {
        return _getConnectedFeed(cToken);
    }

    function exposed_convertDecimalsForComptroller(
        uint256 value,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external pure returns (uint256) {
        return
            _convertDecimalsForComptroller(value, decimals, underlyingDecimals);
    }

    function exposed_validateAddress(address addr) external pure {
        _validateAddress(addr);
    }

    function exposed_validateFeed(Feed memory fd, AggregatorV3Interface feed)
        external
        pure
    {
        _validateFeed(fd, feed);
    }

    function exposed_validateFeedAndPriceArrays(
        AggregatorV3Interface[] memory feeds,
        uint256[] memory prices
    ) external pure {
        _validateFeedAndPriceArrays(feeds, prices);
    }

    function exposed_validatePrice(uint256 price) external pure {
        _validatePrice(price);
    }
}
