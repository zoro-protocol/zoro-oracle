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

    event NewPrice(AggregatorV3Interface indexed feed, uint256 price);

    function setUp() public {
        oracle = new PriceOracle(address(this), msg.sender, msg.sender);
    }

    function test_RevertIfCallerIsNotPermitted() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        FeedData memory fd = FeedData(cToken, decimals, underlyingDecimals);

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setUnderlyingPrice(feed, price);
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        FeedData memory fd = FeedData(cToken, decimals, underlyingDecimals);

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)

        vm.expectEmit();
        emit NewPrice(feed, price);
        oracle.setUnderlyingPrice(feed, price);
    }

    function test_SetFirstPriceData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        FeedData memory fd = FeedData(cToken, decimals, underlyingDecimals);

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        oracle.setUnderlyingPrice(feed, price);

        PriceData memory pd = oracle.exposed_priceData(cToken);

        assertEq(address(pd.feed), address(feed));
        assertEq(pd.price, price);
    }

    function test_UpdatePriceData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        FeedData memory fd = FeedData(cToken, decimals, underlyingDecimals);

        oracle.workaround_setFeedData(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        oracle.setUnderlyingPrice(feed, price);

        uint256 newPrice = 11e7; // $1.10
        oracle.setUnderlyingPrice(feed, newPrice);

        PriceData memory pd = oracle.exposed_priceData(cToken);

        assertEq(address(pd.feed), address(feed));
        assertEq(pd.price, newPrice);
    }
}
