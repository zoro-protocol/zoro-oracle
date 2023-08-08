// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {InvalidTimestamp, PriceData} from "src/AnchoredPriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/AnchoredPriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidateTimestamp is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_NoRevertIfNew() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 oldPrice = 1e18;
        uint256 oldTimestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, oldPrice, oldTimestamp);

        uint256 newTimestamp = block.timestamp + 1 days;

        oracle.exposed_validateTimestamp(pd, newTimestamp);

        assertTrue(true, "Must not revert");
    }

    function test_RevertIfOld() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 oldPrice = 1e18;
        uint256 oldTimestamp = block.timestamp + 1 days;
        PriceData memory pd = PriceData(feed, oldPrice, oldTimestamp);

        uint256 newTimestamp = block.timestamp;

        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimestamp.selector, newTimestamp)
        );
        oracle.exposed_validateTimestamp(pd, newTimestamp);
    }
}
