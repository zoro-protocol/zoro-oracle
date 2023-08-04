// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract UseDefault is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_DefaultIfZero() public {
        uint256 value = 0;
        uint256 defaultValue = type(uint256).max;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = defaultValue;
        assertEq(result, expected);
    }

    function test_ValueIfGtZero() public {
        uint256 value = 10;
        uint256 defaultValue = type(uint256).max;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = value;
        assertEq(result, expected);
    }

    function test_ZeroIfBothZero() public {
        uint256 value = 0;
        uint256 defaultValue = 0;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = 0;
        assertEq(result, expected);
    }
}
