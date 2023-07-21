// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {InvalidTimestamp, PriceData, PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
    }

    function test_validateTimestamp_noRevertIfNew() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 oldPrice = 1e18;
        uint256 oldTimestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, oldPrice, oldTimestamp);

        uint256 newTimestamp = block.timestamp + 1 days;

        oracle.exposed_validateTimestamp(pd, newTimestamp);

        assertTrue(true, "Must not revert");
    }

    function test_validateTimestamp_revertIfOld() public {
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
