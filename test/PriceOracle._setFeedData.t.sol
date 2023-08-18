// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetFeedData is Test {
    PriceOracle public oracle;

    event UpdateFeed(AggregatorV3Interface indexed feed, CToken indexed cToken);

    function setUp() public {
        oracle = new PriceOracle(msg.sender, address(this), msg.sender);
    }

    function test_SetFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.setFeedData(feed, cToken, decimals, underlyingDecimals);

        (
            CToken fdCtoken,
            uint256 fdDecimals,
            uint256 fdUnderlyingDecimals
        ) = oracle.feedData(feed);

        assertEq(address(fdCtoken), address(cToken));
        assertEq(fdDecimals, decimals);
        assertEq(fdUnderlyingDecimals, underlyingDecimals);
    }

    function test_SetFeedAddress() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.setFeedData(feed, cToken, decimals, underlyingDecimals);

        address[] memory addresses = oracle.getFeedAddresses();

        assertEq(addresses.length, 1);
        assertEq(addresses[0], feedAddress);
    }

    function test_UpdateIfDuplicateFeedAddress() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.setFeedData(feed, cToken, decimals, underlyingDecimals);

        address newCTokenAddress = makeAddr("newCToken");
        CToken newCToken = CToken(newCTokenAddress);
        uint256 newDecimals = 10;
        uint256 newUnderlyingDecimals = 8;

        oracle.setFeedData(feed, newCToken, newDecimals, newUnderlyingDecimals);

        address[] memory addresses = oracle.getFeedAddresses();

        assertEq(addresses.length, 1);
        assertEq(addresses[0], feedAddress);

        (
            CToken fdCtoken,
            uint256 fdDecimals,
            uint256 fdUnderlyingDecimals
        ) = oracle.feedData(feed);

        assertEq(address(fdCtoken), address(newCToken));
        assertEq(fdDecimals, newDecimals);
        assertEq(fdUnderlyingDecimals, newUnderlyingDecimals);
    }
}
