// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";
import {IFeedRegistry, FeedData, MAX_DELTA_BASE, DEFAULT_MAX_DELTA_MANTISSA, DEFAULT_LIVE_PERIOD} from "/IFeedRegistry.sol";
import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";

contract PriceOracle is IFeedRegistry, IPriceReceiver, IPriceOracle, Ownable {
    using Math for uint256;

    mapping(CToken => PriceData) priceData;
    mapping(AggregatorV3Interface => FeedData) feedData;

    error InvalidTimestamp(uint256 timestamp);
    error PriceIsZero();
    error PriceExceededDelta(uint256 oldPrice, uint256 price);
    error PriceIsStale(uint256 timestamp);

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

    function setUnderlyingPrice(
        AggregatorV3Interface feed,
        uint256 price,
        uint256 timestamp
    ) external onlyOwner {
        (PriceData memory oldPd, FeedData memory fd) = _getData(feed);

        _validateTimestamp(oldPd, timestamp);
        _validatePrice(oldPd, fd, price);

        priceData[fd.cToken] = PriceData(feed, price, timestamp);

        emit NewPrice(feed, price, timestamp);
    }

    /**
     * @notice Set data parameters to zero for default values
     */
    function setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external onlyOwner {
        feedData[feed] = FeedData(cToken, livePeriod, maxDeltaMantissa);

        emit UpdateFeed(feed, cToken, livePeriod, maxDeltaMantissa);
    }

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

    function _getData(CToken cToken)
        private
        view
        returns (PriceData memory, FeedData memory)
    {
        PriceData storage pd = priceData[cToken];
        FeedData storage fd = feedData[pd.feed];

        return (pd, fd);
    }

    function _getData(AggregatorV3Interface feed)
        private
        view
        returns (PriceData memory, FeedData memory)
    {
        FeedData storage fd = feedData[feed];
        PriceData storage pd = priceData[fd.cToken];

        return (pd, fd);
    }

    function _validateLiveness(FeedData memory fd, uint256 timestamp)
        private
        view
    {
        uint256 livePeriod = _useDefault(fd.livePeriod, DEFAULT_LIVE_PERIOD);

        if (timestamp + livePeriod < block.timestamp)
            revert PriceIsStale(timestamp);
    }

    function _validateTimestamp(PriceData memory pd, uint256 timestamp)
        private
        pure
    {
        if (timestamp < pd.timestamp) revert InvalidTimestamp(timestamp);
    }

    function _validatePrice(
        PriceData memory pd,
        FeedData memory fd,
        uint256 price
    ) private pure {
        if (price == 0) revert PriceIsZero();

        uint256 oldPrice = pd.price;
        uint256 delta = price.max(oldPrice) - price.min(oldPrice);

        if (delta > 0) {
            uint256 deltaMantissa = oldPrice.mulDiv(MAX_DELTA_BASE, delta);

            uint256 maxDeltaMantissa = _useDefault(
                fd.maxDeltaMantissa,
                DEFAULT_MAX_DELTA_MANTISSA
            );

            if (deltaMantissa > maxDeltaMantissa)
                revert PriceExceededDelta(oldPrice, price);
        }
    }

    function _useDefault(uint256 value, uint256 defaultValue)
        private
        pure
        returns (uint256)
    {
        return value > 0 ? value : defaultValue;
    }
}
