// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ConnectCTokenToFeed is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfCTokenIsZeroAddress() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = address(0);
        CToken cToken = CToken(cTokenAddress);

        vm.expectRevert(BasePriceOracle.InvalidAddress.selector);
        oracle.exposed_connectCTokenToFeed(cToken, feed);
    }

    function test_RevertIfFeedIsZeroAddress() public {
        address feedAddress = address(0);
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        vm.expectRevert(BasePriceOracle.InvalidAddress.selector);
        oracle.exposed_connectCTokenToFeed(cToken, feed);
    }

    function test_RevertIfFeedNotConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.FeedNotConfigured.selector,
                feed
            )
        );
        oracle.exposed_connectCTokenToFeed(cToken, feed);
    }

    function test_ConnectCTokenIfFeedConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        oracle.exposed_connectCTokenToFeed(cToken, feed);

        AggregatorV3Interface newFeed = oracle.connectedFeeds(cToken);

        assertEq(address(newFeed), address(feed));
    }
}
