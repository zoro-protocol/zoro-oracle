// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {Feed} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ConfigureFeed is Test {
    PriceOracle public oracle;

    event UpdateFeed(AggregatorV3Interface indexed feed, CToken indexed cToken);

    function setUp() public {
        oracle = new PriceOracle(msg.sender, address(this), msg.sender);
    }

    function test_RevertIfFeedIsZeroAddress() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        vm.expectRevert(
            abi.encodeWithSelector(BasePriceOracle.InvalidAddress.selector)
        );
        oracle.configureFeed(feed, decimals, underlyingDecimals);
    }

    function test_ConfigureFeed() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.configureFeed(feed, decimals, underlyingDecimals);

        (
            AggregatorV3Interface fdFeed,
            uint256 fdDecimals,
            uint256 fdUnderlyingDecimals
        ) = oracle.allFeeds(feed);

        assertEq(address(fdFeed), address(feed));
        assertEq(fdDecimals, decimals);
        assertEq(fdUnderlyingDecimals, underlyingDecimals);
    }

    function test_NewFeedIsAddedToListOfAddresses() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.configureFeed(feed, decimals, underlyingDecimals);

        address[] memory addresses = oracle.getFeedAddresses();

        assertEq(addresses.length, 1);
        assertEq(addresses[0], feedAddress);
    }

    function test_UpdateIfDuplicateFeedAddress() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;

        oracle.configureFeed(feed, decimals, underlyingDecimals);

        uint256 newDecimals = 10;
        uint256 newUnderlyingDecimals = 8;

        oracle.configureFeed(feed, newDecimals, newUnderlyingDecimals);

        address[] memory addresses = oracle.getFeedAddresses();

        assertEq(addresses.length, 1);
        assertEq(addresses[0], feedAddress);

        (, uint256 fdDecimals, uint256 fdUnderlyingDecimals) = oracle.allFeeds(
            feed
        );

        assertEq(fdDecimals, newDecimals);
        assertEq(fdUnderlyingDecimals, newUnderlyingDecimals);
    }
}
