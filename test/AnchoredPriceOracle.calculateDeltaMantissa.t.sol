// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {MAX_DELTA_BASE} from "src/AnchoredPriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/AnchoredPriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract CalculateDeltaMantissa is Test {
    using Math for uint256;

    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function testFuzz_ZeroIfNoPriceChange(uint256 oldPrice) public {
        uint256 expectedDelta = 0;

        uint256 newPrice = oldPrice;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertEq(deltaMantissa, expectedDelta);
    }

    function testFuzz_ZeroIfOldPriceIsZero(uint256 newPrice) public {
        uint256 expectedDelta = 0;

        uint256 oldPrice = 0;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertEq(deltaMantissa, expectedDelta);
    }

    function testFuzz_MaxUintIfCalcOverflows(uint256 oldPrice, uint256 newPrice)
        public
    {
        vm.assume(oldPrice > 0);

        uint256 percentChange = (newPrice.max(oldPrice) -
            newPrice.min(oldPrice)) / oldPrice;

        uint256 maxChangeBeforeOverflow = type(uint256).max / MAX_DELTA_BASE;

        vm.assume(percentChange > maxChangeBeforeOverflow);

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        uint256 expectedDelta = type(uint256).max;
        assertEq(deltaMantissa, expectedDelta);
    }

    function test_PositiveDeltaIfPriceChanges(
        uint256 oldPrice,
        uint256 newPrice
    ) public {
        // Condition when `oldPrice` is invalid
        vm.assume(oldPrice > 0);

        // Condition when delta is small enough to round to zero
        uint256 delta = oldPrice.max(newPrice) - oldPrice.min(newPrice);
        vm.assume(delta > oldPrice / MAX_DELTA_BASE);

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertGt(deltaMantissa, 0);
    }

    function testFuzz_ZeroDeltaWhenChangeIsTooSmall(
        uint256 oldPrice,
        uint256 newPrice
    ) public {
        // Condition when `oldPrice` is invalid
        vm.assume(oldPrice > 0);

        // Condition when delta is small enough to round to zero
        uint256 delta = oldPrice.max(newPrice) - oldPrice.min(newPrice);
        vm.assume(delta < oldPrice / MAX_DELTA_BASE);

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertEq(deltaMantissa, 0);
    }
}
