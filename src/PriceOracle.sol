// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";
import {IFeedRegistry, FeedData, MAX_DELTA_BASE, DEFAULT_MAX_DELTA_MANTISSA, DEFAULT_LIVE_PERIOD} from "/IFeedRegistry.sol";
import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";

error InvalidTimestamp(uint256 timestamp);
error PriceIsZero();
error PriceIsStale(uint256 timestamp);

contract PriceOracle is
    IFeedRegistry,
    IPriceReceiver,
    IPriceOracle,
    ReentrancyGuard,
    Ownable
{
    using Math for uint256;

    mapping(CToken => PriceData) priceData;
    mapping(AggregatorV3Interface => FeedData) feedData;

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

    event PriceExceededDelta(uint256 oldPrice, uint256 price);

    function setUnderlyingPrice(
        AggregatorV3Interface feed,
        uint256 price,
        uint256 timestamp
    ) external onlyOwner nonReentrant {
        (PriceData memory oldPd, FeedData memory fd) = _getData(feed);

        _validateTimestamp(oldPd, timestamp);
        _validatePrice(price);

        uint256 newPrice = _sanitizePrice(oldPd, fd, price);

        priceData[fd.cToken] = PriceData(feed, newPrice, timestamp);

        emit NewPrice(feed, newPrice, timestamp);
    }

    /**
     * @notice Set data parameters to zero for default values
     */
    function setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external onlyOwner nonReentrant {
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

    function _sanitizePrice(
        PriceData memory pd,
        FeedData memory fd,
        uint256 price
    ) internal returns (uint256) {
        uint256 oldPrice = pd.price;

        uint256 deltaMantissa = _calculateDeltaMantissa(oldPrice, price);

        uint256 maxDeltaMantissa = _useDefault(
            fd.maxDeltaMantissa,
            DEFAULT_MAX_DELTA_MANTISSA
        );

        uint256 newPrice = 0;

        if (deltaMantissa <= maxDeltaMantissa) newPrice = price;
        else {
            newPrice = price > oldPrice
                ? oldPrice + maxDeltaMantissa
                : oldPrice - maxDeltaMantissa;

            emit PriceExceededDelta(oldPrice, price);
        }

        return newPrice;
    }

    function _getData(CToken cToken)
        internal
        view
        returns (PriceData memory, FeedData memory)
    {
        PriceData storage pd = priceData[cToken];
        FeedData storage fd = feedData[pd.feed];

        return (pd, fd);
    }

    function _getData(AggregatorV3Interface feed)
        internal
        view
        returns (PriceData memory, FeedData memory)
    {
        FeedData storage fd = feedData[feed];
        PriceData storage pd = priceData[fd.cToken];

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

    function _validateTimestamp(PriceData memory pd, uint256 timestamp)
        internal
        pure
    {
        if (timestamp < pd.timestamp) revert InvalidTimestamp(timestamp);
    }

    function _validatePrice(uint256 price) internal pure {
        if (price == 0) revert PriceIsZero();
    }

    function _calculateDeltaMantissa(uint256 oldPrice, uint256 newPrice)
        internal
        pure
        returns (uint256)
    {
        uint256 delta = newPrice.max(oldPrice) - newPrice.min(oldPrice);

        return delta > 0 ? oldPrice.mulDiv(MAX_DELTA_BASE, delta) : 0;
    }

    function _useDefault(uint256 value, uint256 defaultValue)
        internal
        pure
        returns (uint256)
    {
        return value > 0 ? value : defaultValue;
    }
}
