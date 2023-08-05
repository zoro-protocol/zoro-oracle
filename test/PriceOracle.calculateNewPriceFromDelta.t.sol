// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract CalculateNewPriceFromDelta is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_NoPriceChangeIfDeltaIsZero() public {
        uint256 oldPrice = 1e8; // $1
        uint256 deltaMantissa = 0;
        uint256 newPrice = oracle.exposed_calculateNewPriceFromDelta(
            oldPrice,
            deltaMantissa,
            false
        );

        uint256 expectedPrice = oldPrice;
        assertEq(newPrice, expectedPrice);
    }

    function test_PriceChangeIfDeltaIsNegative() public {
        uint256 oldPrice = 1e8; // $1
        uint256 deltaMantissa = 1e17; // 10%
        uint256 newPrice = oracle.exposed_calculateNewPriceFromDelta(
            oldPrice,
            deltaMantissa,
            true
        );

        uint256 expectedPrice = 9e7; // $0.90
        assertEq(newPrice, expectedPrice);
    }

    function test_PriceChangeIfDeltaIsPositive() public {
        uint256 oldPrice = 1e8; // $1
        uint256 deltaMantissa = 1e17; // 10%
        uint256 newPrice = oracle.exposed_calculateNewPriceFromDelta(
            oldPrice,
            deltaMantissa,
            false
        );

        uint256 expectedPrice = 11 * 1e7; // $1.10
        assertEq(newPrice, expectedPrice);
    }

    function test_ZeroIfNewPriceIsNegative() public {
        uint256 oldPrice = 1e8; // $1
        uint256 deltaMantissa = 2e18; // 200%
        uint256 newPrice = oracle.exposed_calculateNewPriceFromDelta(
            oldPrice,
            deltaMantissa,
            true
        );

        uint256 expectedPrice = 0; // $0.00
        assertEq(newPrice, expectedPrice);
    }
}
