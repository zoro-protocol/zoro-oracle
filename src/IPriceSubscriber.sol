// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface IPriceSubscriber {
    function setUnderlyingPrice(AggregatorV3Interface feed, uint256 price)
        external;
}
