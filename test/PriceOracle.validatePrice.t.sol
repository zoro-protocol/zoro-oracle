// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidatePrice is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfPriceIsZero() public {
        uint256 price = 0;

        vm.expectRevert(BasePriceOracle.PriceIsZero.selector);
        oracle.exposed_validatePrice(price);
    }

    function test_NoRevertIfPriceIsNonZero() public {
        uint256 price = 1e8;

        oracle.exposed_validatePrice(price);

        assertTrue(true, "Must not revert");
    }
}
