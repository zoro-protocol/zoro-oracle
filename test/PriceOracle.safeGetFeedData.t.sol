// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {FeedNotConfigured} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SafeGetFeedData is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfFeedNotSet() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(FeedNotConfigured.selector, feed)
        );
        oracle.exposed_safeGetFeedData(feed);
    }

    function test_RevertIfCTokenNotSet() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = address(0);
        uint256 decimals = 8;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(
                CToken(cTokenAddress),
                decimals,
                livePeriod,
                maxDeltaMantissa
            )
        );

        vm.expectRevert(
            abi.encodeWithSelector(FeedNotConfigured.selector, feed)
        );
        oracle.exposed_safeGetFeedData(feed);
    }

    function test_ReturnFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        uint256 decimals = 8;
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(
                CToken(cTokenAddress),
                decimals,
                livePeriod,
                maxDeltaMantissa
            )
        );

        FeedData memory fd = oracle.exposed_safeGetFeedData(feed);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);
    }
}
