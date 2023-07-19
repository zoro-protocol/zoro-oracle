// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CToken, PriceOracle as IPriceOracle} from "@zoro-protocol/PriceOracle.sol";

contract PriceOracle is IPriceOracle {
    function getUnderlyingPrice(CToken cToken)
        external
        view
        override
        returns (uint256)
    {}
}
