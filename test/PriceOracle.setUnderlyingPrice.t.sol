// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetUnderlyingPrice is Test {
    PriceOracle public oracle;

    event NewPrice(AggregatorV3Interface indexed feed, uint256 price);

    function setUp() public {
        oracle = new PriceOracle(address(this), msg.sender, msg.sender);
    }

    function test_RevertIfCallerIsNotPermitted() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setUnderlyingPrice(feed, price);
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)

        vm.expectEmit();
        emit NewPrice(feed, price);
        oracle.setUnderlyingPrice(feed, price);
    }
}
