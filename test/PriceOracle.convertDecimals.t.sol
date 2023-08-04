// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ConvertDecimals is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_ConvertToPriceMantissaDecimals() public {
        uint256 value = 100 * 1e8;
        uint256 decimals = 8;

        uint256 convertedValue = oracle.exposed_convertDecimals(
            value,
            decimals
        );

        uint256 expected = 100 * 1e18;
        assertEq(convertedValue, expected);
    }
}
