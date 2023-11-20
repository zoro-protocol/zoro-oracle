// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

import {AggregatorV3Interface, CToken, EnumerableSet, FeedData, BasePriceOracle} from "src/BasePriceOracle.sol";

contract PriceOracleHarness is BasePriceOracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        address pricePublisher,
        address feedAdmin,
        address defaultAdmin
    ) BasePriceOracle(pricePublisher, feedAdmin, defaultAdmin) {}

    function workaround_setFeedData(
        AggregatorV3Interface feed,
        FeedData calldata fd
    ) external {
        feedData[feed] = fd;
    }

    function workaround_setCTokenFeed(CToken cToken, AggregatorV3Interface feed)
        external
    {
        cTokenFeeds[cToken] = feed;
    }

    function workaround_setFeedAddress(address feed) external {
        _feedAddresses.add(feed);
    }

    function workaround_setPrice(AggregatorV3Interface feed, uint256 price)
        external
    {
        _prices[feed] = price;
    }

    function exposed_setFeedData(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external {
        _setFeedData(feed, decimals, underlyingDecimals);
    }

    function exposed_setCTokenFeed(CToken cToken, AggregatorV3Interface feed)
        external
    {
        _setCTokenFeed(cToken, feed);
    }

    function exposed_getFeedData(CToken cToken)
        external
        view
        returns (FeedData memory)
    {
        return _getFeedData(cToken);
    }

    function exposed_prices(AggregatorV3Interface feed)
        external
        view
        returns (uint256)
    {
        return _prices[feed];
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

    function exposed_validatePrice(uint256 price) external pure {
        _validatePrice(price);
    }
}
