// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidateAddress is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfAddressIsZero() public {
        address addr = address(0);

        vm.expectRevert(BasePriceOracle.InvalidAddress.selector);
        oracle.exposed_validateAddress(addr);
    }

    function test_NoRevertIfAddressIsNonZero() public {
        address addr = address(oracle);

        oracle.exposed_validateAddress(addr);

        assertTrue(true, "Must not revert");
    }
}
