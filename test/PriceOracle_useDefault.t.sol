// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
    }

    function test_useDefault_defaultIfZero() public {
        uint256 value = 0;
        uint256 defaultValue = type(uint256).max;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = defaultValue;
        assertEq(result, expected);
    }

    function test_useDefault_valueIfGtZero() public {
        uint256 value = 10;
        uint256 defaultValue = type(uint256).max;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = value;
        assertEq(result, expected);
    }

    function test_useDefault_zeroIfBothZero() public {
        uint256 value = 0;
        uint256 defaultValue = 0;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = 0;
        assertEq(result, expected);
    }
}
