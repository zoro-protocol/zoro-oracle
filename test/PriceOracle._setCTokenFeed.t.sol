// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {InvalidAddress} from "src/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract SetCTokenFeed is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_revertIfCTokenIsZeroAddress() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = address(0);
        CToken cToken = CToken(cTokenAddress);

        vm.expectRevert(abi.encodeWithSelector(InvalidAddress.selector));
        oracle.exposed_setCTokenFeed(cToken, feed);
    }

    function test_revertIfFeedIsZeroAddress() public {
        address feedAddress = address(0);
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        vm.expectRevert(abi.encodeWithSelector(InvalidAddress.selector));
        oracle.exposed_setCTokenFeed(cToken, feed);
    }

    function test_MapFeedToCToken() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        oracle.exposed_setCTokenFeed(cToken, feed);

        AggregatorV3Interface newFeed = oracle.cTokenFeeds(cToken);

        assertEq(address(newFeed), address(feed));
    }
}
