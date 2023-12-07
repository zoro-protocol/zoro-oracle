// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetFeedPrices is Test {
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

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](1);
        feeds[0] = feed;

        uint256[] memory prices = new uint256[](1);
        prices[0] = 1e8; // $1 (8 decimals)

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setFeedPrices(feeds, prices);
    }

    function test_EmitForEveryFeedPrice() public {
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        address feedAddress1 = makeAddr("feed1");
        AggregatorV3Interface feed1 = AggregatorV3Interface(feedAddress1);
        Feed memory fd1 = Feed(feed1, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed1, fd1);

        address feedAddress2 = makeAddr("feed2");
        AggregatorV3Interface feed2 = AggregatorV3Interface(feedAddress2);
        Feed memory fd2 = Feed(feed2, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed2, fd2);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](2);
        feeds[0] = feed1;
        feeds[1] = feed2;

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e8; // $1 (8 decimals)
        prices[1] = 2e8; // $2 (8 decimals)

        for (uint256 i = 0; i < feeds.length; i++) {
            vm.expectEmit();
            emit NewPrice(feeds[i], prices[i]);
        }

        oracle.setFeedPrices(feeds, prices);
    }

    function test_RevertIfAPriceIsInvalid() public {
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        address feedAddress1 = makeAddr("feed1");
        AggregatorV3Interface feed1 = AggregatorV3Interface(feedAddress1);
        Feed memory fd1 = Feed(feed1, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed1, fd1);

        address feedAddress2 = makeAddr("feed2");
        AggregatorV3Interface feed2 = AggregatorV3Interface(feedAddress2);
        Feed memory fd2 = Feed(feed2, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed2, fd2);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](2);
        feeds[0] = feed1;
        feeds[1] = feed2;

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e8; // $1 (8 decimals)
        prices[1] = 0; // $0 (8 decimals)

        vm.expectRevert(BasePriceOracle.PriceIsZero.selector);
        oracle.setFeedPrices(feeds, prices);
    }

    function test_UpdatePricesIfAllDataIsValid() public {
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        address feedAddress1 = makeAddr("feed1");
        AggregatorV3Interface feed1 = AggregatorV3Interface(feedAddress1);
        Feed memory fd1 = Feed(feed1, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed1, fd1);

        address feedAddress2 = makeAddr("feed2");
        AggregatorV3Interface feed2 = AggregatorV3Interface(feedAddress2);
        Feed memory fd2 = Feed(feed2, decimals, underlyingDecimals);
        oracle.workaround_setAllFeeds(feed2, fd2);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](2);
        feeds[0] = feed1;
        feeds[1] = feed2;

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1e8; // $1 (8 decimals)
        prices[1] = 2e8; // $2 (8 decimals)

        oracle.setFeedPrices(feeds, prices);

        assertEq(oracle.feedPrices(feed1), prices[0]);
        assertEq(oracle.feedPrices(feed2), prices[1]);
    }
}
