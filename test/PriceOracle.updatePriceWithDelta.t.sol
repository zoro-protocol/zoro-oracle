// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {MAX_DELTA_BASE} from "src/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract UpdatePriceWithDelta is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function testFuzz_NoPriceChangeIfDeltaIsZero(uint256 oldPrice) public {
        uint256 deltaMantissa = 0;
        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
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
        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
            oldPrice,
            deltaMantissa,
            true
        );

        uint256 expectedPrice = 9e7; // $0.90
        assertEq(newPrice, expectedPrice);
    }

    function testFuzz_PriceChangeIfDeltaIsNegative(
        uint256 oldPrice,
        uint256 deltaMantissa
    ) public {
        // Condition when delta is small enough to round to zero
        vm.assume(oldPrice >= MAX_DELTA_BASE);
        vm.assume(deltaMantissa > oldPrice / MAX_DELTA_BASE);

        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
            oldPrice,
            deltaMantissa,
            true
        );

        if (oldPrice > 0) assertLt(newPrice, oldPrice);
        else assertEq(newPrice, 0);
    }

    function test_PriceChangeIfDeltaIsPositive() public {
        uint256 oldPrice = 1e8; // $1
        uint256 deltaMantissa = 1e17; // 10%
        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
            oldPrice,
            deltaMantissa,
            false
        );

        uint256 expectedPrice = 11 * 1e7; // $1.10
        assertEq(newPrice, expectedPrice);
    }

    function testFuzz_PriceChangeIfDeltaIsPositive(
        uint256 oldPrice,
        uint256 deltaMantissa
    ) public {
        // Condition when delta is small enough to round to zero
        vm.assume(oldPrice >= MAX_DELTA_BASE);
        vm.assume(deltaMantissa > oldPrice / MAX_DELTA_BASE);

        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
            oldPrice,
            deltaMantissa,
            false
        );

        if (oldPrice < type(uint256).max) assertGt(newPrice, oldPrice);
        else assertEq(newPrice, type(uint256).max);
    }

    function testFuzz_ZeroIfNewPriceUnderflows(
        uint256 oldPrice,
        uint256 deltaMantissa
    ) public {
        vm.assume(deltaMantissa > 1e18); // 100%

        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
            oldPrice,
            deltaMantissa,
            true
        );

        uint256 expectedPrice = 0; // $0.00
        assertEq(newPrice, expectedPrice);
    }

    function testFuzz_MaxUintIfNewPriceIsOverflows(
        uint256 oldPrice,
        uint256 deltaMantissa
    ) public {
        vm.assume(oldPrice > type(uint256).max / 2);
        vm.assume(deltaMantissa > 1e18); // 100%
        uint256 newPrice = oracle.exposed_updatePriceWithDelta(
            oldPrice,
            deltaMantissa,
            false
        );

        uint256 expectedPrice = type(uint256).max;
        assertEq(newPrice, expectedPrice);
    }
}
