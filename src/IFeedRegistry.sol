// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {CToken} from "lib/zoro-protocol/contracts/CToken.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

uint256 constant MAX_DELTA_BASE = 1e18;
uint256 constant DEFAULT_FEED_DECIMALS = 8;
uint256 constant DEFAULT_MAX_DELTA_MANTISSA = 20 * 1e16; // 20%
uint256 constant DEFAULT_LIVE_PERIOD = 30 hours;

struct FeedData {
    CToken cToken;
    uint256 decimals;
    uint256 underlyingDecimals;
    uint256 livePeriod;
    uint256 maxDeltaMantissa;
}

interface IFeedRegistry {
    function setFeedData(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 decimals,
        uint256 underlyingDecimals,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external;
}
