// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidateFeed is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfFeedIsNotConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        Feed memory fd = Feed(AggregatorV3Interface(address(0)), 0, 0);

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.FeedNotConfigured.selector,
                feed
            )
        );
        oracle.exposed_validateFeed(fd, feed);
    }

    function test_RevertIfFeedIsConfiguredIncorrect() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address wrongFeedAddress = makeAddr("feed2");
        AggregatorV3Interface wrongFeed = AggregatorV3Interface(
            wrongFeedAddress
        );
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(wrongFeed, decimals, underlyingDecimals);

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.FeedNotConfigured.selector,
                feed
            )
        );
        oracle.exposed_validateFeed(fd, feed);
    }

    function test_NoRevertIfFeedIsConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed, fd);

        oracle.exposed_validateFeed(fd, feed);

        assertTrue(true, "Must not revert");
    }
}
