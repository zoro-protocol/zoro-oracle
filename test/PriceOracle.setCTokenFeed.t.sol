// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetCTokenFeed is Test {
    PriceOracle public oracle;

    event UpdateCTokenFeed(
        CToken indexed cToken,
        AggregatorV3Interface indexed feed
    );

    function setUp() public {
        oracle = new PriceOracle(msg.sender, address(this), msg.sender);
    }

    function test_RevertIfCallerIsNotPermitted() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        FeedData memory fd = FeedData(feed, decimals, underlyingDecimals);

        oracle.workaround_setFeedData(feed, fd);

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setCTokenFeed(cToken, feed);
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        FeedData memory fd = FeedData(feed, decimals, underlyingDecimals);

        oracle.workaround_setFeedData(feed, fd);

        vm.expectEmit();
        emit UpdateCTokenFeed(cToken, feed);
        oracle.setCTokenFeed(cToken, feed);
    }
}
