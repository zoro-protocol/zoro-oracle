// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";
import {IPriceConfig, PriceConfig, MAX_DELTA_BASE, MAX_DELTA_MANTISSA, LIVE_PERIOD} from "/IPriceConfig.sol";

contract PriceOracle is IPriceConfig, IPriceReceiver, IPriceOracle, Ownable {
    mapping(CToken => PriceData) priceData;

    error InvalidTimestamp(uint256 timestamp);
    error PriceIsZero();
    error PriceExceededDelta(uint256 oldPrice, uint256 price);
    error PriceIsStale(uint256 timestamp);

    event NewPrice(CToken cToken, uint256 price, uint256 timestamp);

    function setUnderlyingPrice(
        CToken cToken,
        uint256 price,
        uint256 timestamp
    ) external onlyOwner {
        PriceData storage oldData = priceData[cToken];

        _validateTimestamp(oldData, timestamp);
        _validatePrice(oldData, price);

        priceData[cToken] = PriceData(price, timestamp);

        emit NewPrice(cToken, price, timestamp);
    }

    function setPriceConfig(
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external onlyOwner {}

    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {
        PriceData storage data = priceData[cToken];

        _validateLiveness(data.timestamp);

        return data.price;
    }

    function _validateTimestamp(PriceData memory data, uint256 timestamp)
        private
        pure
    {
        if (timestamp <= data.timestamp) revert InvalidTimestamp(timestamp);
    }

    function _validatePrice(PriceData memory data, uint256 price) private pure {
        if (price == 0) revert PriceIsZero();

        uint256 oldPrice = data.price;
        uint256 delta = price > oldPrice ? price - oldPrice : oldPrice - price;
        uint256 deltaMantissa = (oldPrice * MAX_DELTA_BASE) / delta;

        if (deltaMantissa > MAX_DELTA_MANTISSA)
            revert PriceExceededDelta(oldPrice, price);
    }

    function _validateLiveness(uint256 timestamp) private pure {
        if (timestamp + LIVE_PERIOD < timestamp) revert PriceIsStale(timestamp);
    }
}
