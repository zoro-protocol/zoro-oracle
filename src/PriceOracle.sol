// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";

contract PriceOracle is IPriceReceiver, IPriceOracle, Ownable {
    uint256 constant MAX_DELTA_BASE = 1e18;
    uint256 constant MAX_DELTA_MANTISSA = 20 * 1e16; // 20%

    mapping(CToken => PriceData) priceData;

    error InvalidTimestamp(uint256 timestamp);
    error PriceIsZero();
    error PriceExceededDelta(uint256 oldPrice, uint256 price);

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

    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {
        PriceData storage data = priceData[cToken];

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
}
