// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract GetFeedPrices is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(address(this), msg.sender, msg.sender);
    }

    function test_RevertIfAFeedIsNotConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 price = 1e10;
        oracle.workaround_setPrice(feed, price);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](1);
        feeds[0] = feed;

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.FeedNotConfigured.selector,
                feed
            )
        );
        oracle.getFeedPrices(feeds);
    }

    function test_ReturnEmptyArrayIfFeedsIsEmpty() public {
        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](0);

        uint256[] memory prices = oracle.getFeedPrices(feeds);

        assertEq(prices.length, 0);
    }

    function test_ReturnZeroPriceIfPriceNeverSet() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](1);
        feeds[0] = feed;

        uint256[] memory prices = oracle.getFeedPrices(feeds);

        assertEq(prices.length, feeds.length);
        assertEq(prices[0], 0);
    }

    function test_ReturnPricesForSingleFeed() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        uint256 price = 1e10;
        oracle.workaround_setPrice(feed, price);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](1);
        feeds[0] = feed;

        uint256[] memory prices = oracle.getFeedPrices(feeds);

        assertEq(prices.length, feeds.length);
        assertEq(prices[0], price);
    }

    function test_ReturnPricesForEveryFeed() public {
        address feedAddress1 = makeAddr("feed1");
        AggregatorV3Interface feed1 = AggregatorV3Interface(feedAddress1);

        address feedAddress2 = makeAddr("feed2");
        AggregatorV3Interface feed2 = AggregatorV3Interface(feedAddress2);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd1 = Feed(feed1, decimals, underlyingDecimals);
        Feed memory fd2 = Feed(feed2, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed1, fd1);
        oracle.workaround_setAllFeeds(feed2, fd2);

        uint256 price1 = 1e10;
        oracle.workaround_setPrice(feed1, price1);

        uint256 price2 = 2e10;
        oracle.workaround_setPrice(feed2, price2);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](2);
        feeds[0] = feed1;
        feeds[1] = feed2;

        uint256[] memory prices = oracle.getFeedPrices(feeds);

        assertEq(prices.length, feeds.length);
        assertEq(prices[0], price1);
        assertEq(prices[1], price2);
    }
}
