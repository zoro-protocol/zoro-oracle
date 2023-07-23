// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {CToken} from "zoro-protocol/CToken.sol";
import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";

uint256 constant MAX_DELTA_BASE = 1e18;
uint256 constant DEFAULT_MAX_DELTA_MANTISSA = 20 * 1e16; // 20%
uint256 constant DEFAULT_LIVE_PERIOD = 30 hours;

struct FeedData {
    CToken cToken;
    uint256 livePeriod;
    uint256 maxDeltaMantissa;
}

interface IFeedRegistry {
    function setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external;
}
