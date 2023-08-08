// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData, PriceData} from "src/AnchoredPriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/AnchoredPriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract GetDataFromFeed is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_EmptyPriceIfFeedHasNoPrices() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(
                CToken(cTokenAddress),
                decimals,
                underlyingDecimals,
                livePeriod,
                maxDeltaMantissa
            )
        );

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromFeed(feed);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);

        assertEq(address(pd.feed), address(0));
        assertEq(pd.price, 0);
        assertEq(pd.timestamp, 0);
    }

    function test_ReturnPriceDataAndFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(
                cToken,
                decimals,
                underlyingDecimals,
                livePeriod,
                maxDeltaMantissa
            )
        );

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromFeed(feed);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);
        assertEq(pd.timestamp, timestamp);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);
    }
}
