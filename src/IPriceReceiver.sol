// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {CToken} from "zoro-protocol/CToken.sol";
import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";

struct PriceData {
    AggregatorV3Interface feed;
    uint256 price;
    uint256 timestamp;
}

interface IPriceReceiver {
    function setUnderlyingPrice(
        AggregatorV3Interface feed,
        uint256 price,
        uint256 timestamp
    ) external;
}
