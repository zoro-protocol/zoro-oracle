// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";
import {IPriceConfig, PriceConfig, MAX_DELTA_BASE, DEFAULT_MAX_DELTA_MANTISSA, DEFAULT_LIVE_PERIOD} from "/IPriceConfig.sol";

contract PriceOracle is IPriceConfig, IPriceReceiver, IPriceOracle, Ownable {
    mapping(CToken => PriceData) priceData;
    mapping(CToken => PriceConfig) priceConfig;

    error InvalidTimestamp(uint256 timestamp);
    error PriceIsZero();
    error PriceExceededDelta(uint256 oldPrice, uint256 price);
    error PriceIsStale(uint256 timestamp);

    event NewPrice(CToken cToken, uint256 price, uint256 timestamp);
    event UpdatePriceConfig(
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    );

    function setUnderlyingPrice(
        CToken cToken,
        uint256 price,
        uint256 timestamp
    ) external onlyOwner {
        PriceData storage oldData = priceData[cToken];
        PriceConfig storage config = priceConfig[cToken];

        _validateTimestamp(oldData, timestamp);
        _validatePrice(oldData, config, price);

        priceData[cToken] = PriceData(price, timestamp);

        emit NewPrice(cToken, price, timestamp);
    }

    /**
     * @notice Set config parameters to zero for default values
     */
    function setPriceConfig(
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external onlyOwner {
        priceConfig[cToken] = PriceConfig(livePeriod, maxDeltaMantissa);

        emit UpdatePriceConfig(cToken, livePeriod, maxDeltaMantissa);
    }

    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {
        PriceData storage data = priceData[cToken];
        PriceConfig storage config = priceConfig[cToken];

        _validateLiveness(config, data.timestamp);

        return data.price;
    }

    function _validateTimestamp(PriceData memory data, uint256 timestamp)
        private
        pure
    {
        if (timestamp <= data.timestamp) revert InvalidTimestamp(timestamp);
    }

    function _validatePrice(
        PriceData memory data,
        PriceConfig memory config,
        uint256 price
    ) private pure {
        if (price == 0) revert PriceIsZero();

        uint256 oldPrice = data.price;
        uint256 delta = price > oldPrice ? price - oldPrice : oldPrice - price;
        uint256 deltaMantissa = (oldPrice * MAX_DELTA_BASE) / delta;

        uint256 maxDeltaMantissa = config.maxDeltaMantissa > 0
            ? config.maxDeltaMantissa
            : DEFAULT_MAX_DELTA_MANTISSA;

        if (deltaMantissa > maxDeltaMantissa)
            revert PriceExceededDelta(oldPrice, price);
    }

    function _validateLiveness(PriceConfig memory config, uint256 timestamp)
        private
        pure
    {
        uint256 livePeriod = config.livePeriod > 0
            ? config.livePeriod
            : DEFAULT_LIVE_PERIOD;

        if (timestamp + livePeriod < timestamp) revert PriceIsStale(timestamp);
    }
}
