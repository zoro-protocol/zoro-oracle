// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData} from "src/AnchoredPriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/AnchoredPriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetFeedData is Test {
    PriceOracle public oracle;

    event UpdateFeed(
        AggregatorV3Interface feed,
        CToken cToken,
        uint256 livePeriod,
        uint256 maxDeltaMantissa
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
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setFeedData(
            feed,
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%

        vm.expectEmit();
        emit UpdateFeed(feed, cToken, livePeriod, maxDeltaMantissa);
        oracle.setFeedData(
            feed,
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );
    }

    function test_SetFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%

        oracle.setFeedData(
            feed,
            cToken,
            decimals,
            underlyingDecimals,
            livePeriod,
            maxDeltaMantissa
        );

        (
            CToken fdCtoken,
            uint256 fdDecimals,
            uint256 fdUnderlyingDecimals,
            uint256 fdLivePeriod,
            uint256 fdMaxDeltaMantissa
        ) = oracle.feedData(feed);

        assertEq(address(fdCtoken), address(cToken));
        assertEq(fdDecimals, decimals);
        assertEq(fdUnderlyingDecimals, underlyingDecimals);
        assertEq(fdLivePeriod, livePeriod);
        assertEq(fdMaxDeltaMantissa, maxDeltaMantissa);
    }
}