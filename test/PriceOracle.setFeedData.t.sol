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

    function test_RevertIfCallerIsNotPermitted() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        vm.expectRevert();
        hoax(msg.sender);
        oracle.setFeedData(feed, cToken, decimals, underlyingDecimals);
    }

    function test_EmitOnSuccess() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        vm.expectEmit();
        emit UpdateFeed(feed, cToken);
        oracle.setFeedData(feed, cToken, decimals, underlyingDecimals);
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
}
