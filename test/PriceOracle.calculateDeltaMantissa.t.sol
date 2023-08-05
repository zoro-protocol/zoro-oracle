// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {MAX_DELTA_BASE} from "src/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract CalculateDeltaMantissa is Test {
    using Math for uint256;

    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_ZeroIfNoPriceChange() public {
        uint256 expectedDelta = 0;

        uint256 oldPrice = 100;
        uint256 newPrice = 100;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertEq(deltaMantissa, expectedDelta);
    }

    function testFuzz_Overflow(uint256 oldPrice, uint256 newPrice) public {
        vm.assume(oldPrice > 0);

        uint256 percentChange = (newPrice.max(oldPrice) -
            newPrice.min(oldPrice)) / oldPrice;

        uint256 maxChangeBeforeOverflow = type(uint256).max / MAX_DELTA_BASE;

        vm.assume(percentChange > maxChangeBeforeOverflow);

        uint256 expectedDelta = 0;

        vm.expectRevert();
        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertEq(deltaMantissa, expectedDelta);
    }

    function test_PositiveDeltaWhenNegativeChange() public {
        uint256 oldPrice = 100;
        uint256 newPrice = 90;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        uint256 expected = 1 * 1e17; // 10%
        assertEq(deltaMantissa, expected);
    }

    function test_PositiveDeltaWhenPositiveChange() public {
        uint256 oldPrice = 100;
        uint256 newPrice = 110;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        uint256 expected = 1e17; // 10%
        assertEq(deltaMantissa, expected);
    }
}
