// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {CToken} from "@zoro-protocol/CToken.sol";

uint256 constant MAX_DELTA_BASE = 1e18;
uint256 constant MAX_DELTA_MANTISSA = 20 * 1e16; // 20%
uint256 constant LIVE_PERIOD = 30 hours;

struct PriceConfig {
    uint256 livePeriod;
    uint256 maxDeltaMantissa;
}

interface IPriceConfig {
    function setPriceConfig(
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
    ) external;
}
