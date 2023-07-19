// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";
import {IPriceReceiver, PriceData} from "/IPriceReceiver.sol";

contract PriceOracle is IPriceReceiver, IPriceOracle, Ownable {
    function setUnderlyingPrice(
        CToken cToken,
        uint256 price,
        uint256 timestamp
    ) external onlyOwner {}

    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {}
}
