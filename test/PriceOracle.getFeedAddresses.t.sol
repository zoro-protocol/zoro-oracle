// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract GetFeedAddresses is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, address(this), msg.sender);
    }

    function test_ArrayOfAddressesIfFeedsAreConfigured() public {
        address feedAddress = makeAddr("feed");
        oracle.workaround_setFeedAddress(feedAddress);

        address[] memory addresses = oracle.getFeedAddresses();

        assertEq(addresses.length, 1);
        assertEq(addresses[0], feedAddress);
    }

    function test_EmptyArrayIfNoFeedsAreConfigured() public {
        address[] memory addresses = oracle.getFeedAddresses();

        assertEq(addresses.length, 0);
    }
}
