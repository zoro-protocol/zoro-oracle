// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";

contract PriceOracle is IPriceReceiver, IPriceOracle, Ownable {
    mapping(CToken => PriceData) priceData;

    error InvalidTimestamp(uint256 timestamp);

    function setUnderlyingPrice(
        CToken cToken,
        uint256 price,
        uint256 timestamp
    ) external onlyOwner {
        PriceData storage oldData = priceData[cToken];

        _validateTimestamp(oldData, timestamp);
    }

    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {}

    function _validateTimestamp(PriceData data, uint256 timestamp) private {
        if (timestamp <= data.timestamp) revert InvalidTimestamp(timestamp);
    }
}
