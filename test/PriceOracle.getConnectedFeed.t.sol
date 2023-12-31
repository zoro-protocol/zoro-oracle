// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract GetConnectedFeed is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfCTokenIsZeroAddress() public {
        CToken cToken = CToken(address(0));

        vm.expectRevert(
            abi.encodeWithSelector(BasePriceOracle.InvalidAddress.selector)
        );
        oracle.exposed_getConnectedFeed(cToken);
    }

    function test_RevertIfCTokenFeedIsNotSet() public {
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        vm.expectRevert(
            abi.encodeWithSelector(BasePriceOracle.InvalidAddress.selector)
        );
        oracle.exposed_getConnectedFeed(cToken);
    }

    function test_RevertIfFeedNotConfigured() public {
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        oracle.workaround_setConnectedFeeds(cToken, feed);

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.FeedNotConfigured.selector,
                feed
            )
        );
        oracle.exposed_getConnectedFeed(cToken);
    }

    function test_ReturnConnectedFeed() public {
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        oracle.workaround_setConnectedFeeds(cToken, feed);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        oracle.workaround_setAllFeeds(
            feed,
            Feed(feed, decimals, underlyingDecimals)
        );

        Feed memory fd = oracle.exposed_getConnectedFeed(cToken);

        assertEq(address(fd.feed), address(feed));
        assertEq(fd.decimals, decimals);
        assertEq(fd.underlyingDecimals, underlyingDecimals);
    }
}
