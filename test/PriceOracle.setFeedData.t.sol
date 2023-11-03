// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetFeedData is Test {
    PriceOracle public oracle;

    event UpdateFeed(
        AggregatorV3Interface indexed feed,
        uint256 decimals,
        uint256 underlyingDecimals
    );

    function setUp() public {
        oracle = new PriceOracle(msg.sender, address(this), msg.sender);
    }

    function test_RevertIfCallerIsNotPermitted() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setFeedData(feed, decimals, underlyingDecimals);
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        vm.expectEmit();
        emit UpdateFeed(feed, decimals, underlyingDecimals);
        oracle.setFeedData(feed, decimals, underlyingDecimals);
    }

    function test_SetFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.setFeedData(feed, decimals, underlyingDecimals);

        (
            AggregatorV3Interface fdFeed,
            uint256 fdDecimals,
            uint256 fdUnderlyingDecimals
        ) = oracle.feedData(feed);

        assertEq(address(fdFeed), address(feed));
        assertEq(fdDecimals, decimals);
        assertEq(fdUnderlyingDecimals, underlyingDecimals);
    }
}
