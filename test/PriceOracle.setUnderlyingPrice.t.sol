// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {PriceData} from "src/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetUnderlyingPrice is Test {
    PriceOracle public oracle;

    event NewPrice(
        AggregatorV3Interface feed,
        uint256 price,
        uint256 timestamp
    );

    function setUp() public {
        oracle = new PriceOracle(address(this), msg.sender, msg.sender);
    }

    function test_RevertIfCallerIsNotPermitted() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            livePeriod,
            maxDeltaMantissa
        );

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setUnderlyingPrice(feed, price, timestamp);
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            livePeriod,
            maxDeltaMantissa
        );

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;

        vm.expectEmit();
        emit NewPrice(feed, price, timestamp);
        oracle.setUnderlyingPrice(feed, price, timestamp);
    }

    function test_SetFirstPriceData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            livePeriod,
            maxDeltaMantissa
        );

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.setUnderlyingPrice(feed, price, timestamp);

        PriceData memory pd = oracle.exposed_priceData(cToken);

        assertEq(address(pd.feed), address(feed));
        assertEq(pd.price, price);
        assertEq(pd.timestamp, timestamp);
    }

    function test_UpdatePriceData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(
            cToken,
            decimals,
            livePeriod,
            maxDeltaMantissa
        );

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.setUnderlyingPrice(feed, price, timestamp);

        uint256 newPrice = 11e7; // $1.10
        oracle.setUnderlyingPrice(feed, newPrice, timestamp);

        PriceData memory pd = oracle.exposed_priceData(cToken);

        assertEq(address(pd.feed), address(feed));
        assertEq(pd.price, newPrice);
        assertEq(pd.timestamp, timestamp);
    }
}
