// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract CalculateDeltaMantissa is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
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

    function test_PositiveDeltaWhenNegativeChange()
        public
    {
        uint256 oldPrice = 100;
        uint256 newPrice = 90;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        uint256 expected = 1 * 1e17; // 10%
        assertEq(deltaMantissa, expected);
    }

    function test_PositiveDeltaWhenPositiveChange()
        public
    {
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
