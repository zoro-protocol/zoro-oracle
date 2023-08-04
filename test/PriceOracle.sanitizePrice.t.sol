// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {PriceData} from "src/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SanitizePrice is Test {
    PriceOracle public oracle;

    event PriceExceededDelta(uint256 oldPrice, uint256 price, uint256 newPrice);

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_IgnoreMaxDeltaIfOldPriceIsZero() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 oldPrice = 0;
        uint256 timestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, oldPrice, timestamp);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 newPrice = oracle.exposed_sanitizePrice(pd, fd, price);

        assertEq(newPrice, price);
    }

    function test_CapPriceChangeToDefaultMaxDeltaIfMaxDeltaIsZero() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 oldPrice = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, oldPrice, timestamp);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 0;
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );

        // Price change is under the default max delta
        uint256 normalPrice = 109 * 1e6; // 9% increase
        uint256 newPrice = oracle.exposed_sanitizePrice(pd, fd, normalPrice);

        assertEq(newPrice, normalPrice);

        // Price change is over the default max delta
        uint256 abnormalPrice = 10 * 1e8; // 1,000% increase
        uint256 expectedPrice = 12 * 1e7; // 20% increase

        vm.expectEmit(true, true, true, true);
        emit PriceExceededDelta(oldPrice, abnormalPrice, expectedPrice);

        uint256 cappedPrice = oracle.exposed_sanitizePrice(
            pd,
            fd,
            abnormalPrice
        );

        assertEq(cappedPrice, expectedPrice);
    }

    function test_CapPriceChangeToMaxDelta() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 oldPrice = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, oldPrice, timestamp);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );

        // Price change is under the default max delta
        uint256 normalPrice = 109 * 1e6; // 9% increase
        uint256 newPrice = oracle.exposed_sanitizePrice(pd, fd, normalPrice);

        assertEq(newPrice, normalPrice);

        // Price change is over the default max delta
        uint256 abnormalPrice = 10 * 1e8; // 1,000% increase
        uint256 expectedPrice = 11 * 1e7; // 10% increase

        vm.expectEmit(true, true, true, true);
        emit PriceExceededDelta(oldPrice, abnormalPrice, expectedPrice);

        uint256 cappedPrice = oracle.exposed_sanitizePrice(
            pd,
            fd,
            abnormalPrice
        );

        assertEq(cappedPrice, expectedPrice);
    }
}
