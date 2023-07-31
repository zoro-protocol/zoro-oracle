// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {AggregatorV3Interface, CToken, FeedData, PriceData, PriceOracle} from "src/PriceOracle.sol";

contract PriceOracleHarness is PriceOracle {
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

    function workaround_setPriceData(CToken cToken, PriceData calldata pd)
        external
    {
        _priceData[cToken] = pd;
    }

    function exposed_sanitizePrice(
        PriceData memory pd,
        FeedData memory fd,
        uint256 price
    ) external returns (uint256) {
        return _sanitizePrice(pd, fd, price);
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

    function exposed_getDataFromFeed(AggregatorV3Interface feed)
        external
        view
        returns (PriceData memory, FeedData memory)
    {
        return _getData(feed);
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

    function exposed_validateLiveness(FeedData memory fd, uint256 timestamp)
        external
        view
    {
        _validateLiveness(fd, timestamp);
    }

    function exposed_validateAddress(address addr) external pure {
        _validateAddress(addr);
    }

    function exposed_validateTimestamp(PriceData memory pd, uint256 timestamp)
        external
        pure
    {
        _validateTimestamp(pd, timestamp);
    }

    function exposed_calculateDeltaMantissa(uint256 oldPrice, uint256 newPrice)
        external
        pure
        returns (uint256)
    {
        return _calculateDeltaMantissa(oldPrice, newPrice);
    }

    function exposed_calculateNewPriceFromDelta(
        uint256 oldPrice,
        uint256 deltaMantissa,
        bool deltaIsNegative
    ) external pure returns (uint256) {
        return
            _calculateNewPriceFromDelta(
                oldPrice,
                deltaMantissa,
                deltaIsNegative
            );
    }

    function exposed_convertDecimals(uint256 value, uint256 decimals)
        external
        pure
        returns (uint256)
    {
        return _convertDecimals(value, decimals);
    }

    function exposed_useDefault(uint256 value, uint256 defaultValue)
        external
        pure
        returns (uint256)
    {
        return _useDefault(value, defaultValue);
    }
}
