// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {PriceData} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SafeGetFeedData is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_ReturnPriceOfUnderlyingAsset() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, price, timestamp);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(cToken, livePeriod, maxDeltaMantissa);

        oracle.workaround_setFeedData(feed, fd);
        oracle.workaround_setPriceData(cToken, pd);

        uint256 result = oracle.getUnderlyingPrice(cToken);

        uint256 expectedPrice = 1e18;
        assertEq(result, expectedPrice);
    }
}
