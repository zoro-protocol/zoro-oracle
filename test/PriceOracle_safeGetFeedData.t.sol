// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {CToken} from "@zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {FeedNotConfigured} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
    }

    function test_safeGetFeedData_revertIfFeedNotSet() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(FeedNotConfigured.selector, feed)
        );
        oracle.exposed_safeGetFeedData(feed);
    }

    function test_safeGetFeedData_revertIfCTokenNotSet() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = address(0);
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(CToken(cTokenAddress), livePeriod, maxDeltaMantissa)
        );

        vm.expectRevert(
            abi.encodeWithSelector(FeedNotConfigured.selector, feed)
        );
        oracle.exposed_safeGetFeedData(feed);
    }

    function test_safeGetFeedData_returnFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(CToken(cTokenAddress), livePeriod, maxDeltaMantissa)
        );

        FeedData memory fd = oracle.exposed_safeGetFeedData(feed);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);
    }
}
