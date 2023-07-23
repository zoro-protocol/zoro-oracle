// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {InvalidAddress} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
    }

    function test_validateAddress_revertIfAddressIsZero() public {
        address addr = address(0);

        vm.expectRevert(InvalidAddress.selector);
        oracle.exposed_validateAddress(addr);
    }

    function test_validateAddress_noRevertIfAddressIsNonZero() public {
        address addr = address(oracle);

        oracle.exposed_validateAddress(addr);

        assertTrue(true, "Must not revert");
    }
}
