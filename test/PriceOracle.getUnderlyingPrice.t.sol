// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract GetUnderlyingPrice is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfPriceNotSet() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        oracle.workaround_setConnectedFeeds(cToken, feed);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        vm.expectRevert(
            abi.encodeWithSelector(BasePriceOracle.PriceNotSet.selector, cToken)
        );
        oracle.getUnderlyingPrice(cToken);
    }

    function test_ReturnPriceOfUnderlyingAsset() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        oracle.workaround_setConnectedFeeds(cToken, feed);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        Feed memory fd = Feed(feed, decimals, underlyingDecimals);

        oracle.workaround_setAllFeeds(feed, fd);

        uint256 price = 1e8; // $1 (8 decimals)
        oracle.workaround_setPrice(feed, price);

        uint256 result = oracle.getUnderlyingPrice(cToken);

        uint256 expectedPrice = 1e18;
        assertEq(result, expectedPrice);
    }
}
