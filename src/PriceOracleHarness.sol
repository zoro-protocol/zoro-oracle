// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {AggregatorV3Interface, CToken, EnumerableSet, FeedData, PriceData, PriceOracle} from "src/PriceOracle.sol";

contract PriceOracleHarness is PriceOracle {
    using EnumerableSet for EnumerableSet.AddressSet;

    constructor(
        address pricePublisher,
        address feedAdmin,
        address defaultAdmin
    ) PriceOracle(pricePublisher, feedAdmin, defaultAdmin) {}

    function workaround_setFeedData(
        AggregatorV3Interface feed,
        FeedData calldata fd
    ) external {
        feedData[feed] = fd;
    }

    function workaround_setFeedAddress(address feed) external {
        feedAddresses.add(feed);
    }

    function workaround_setPriceData(CToken cToken, PriceData calldata pd)
        external
    {
        _priceData[cToken] = pd;
    }

    function exposed_priceData(CToken cToken)
        external
        view
        returns (PriceData memory)
    {
        return _priceData[cToken];
    }

    function exposed_getDataFromCToken(CToken cToken)
        external
        view
        returns (PriceData memory, FeedData memory)
    {
        return _getData(cToken);
    }

    function exposed_safeGetFeedData(AggregatorV3Interface feed)
        external
        view
        returns (FeedData memory)
    {
        return _safeGetFeedData(feed);
    }

    function exposed_safeGetPriceData(CToken cToken)
        external
        view
        returns (PriceData memory)
    {
        return _safeGetPriceData(cToken);
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
}
