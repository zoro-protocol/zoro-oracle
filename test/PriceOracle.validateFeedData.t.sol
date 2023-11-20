// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidateFeedData is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_RevertIfFeedIsZeroAddress() public {
        address feedAddress = address(0);
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        vm.expectRevert(BasePriceOracle.InvalidAddress.selector);
        oracle.exposed_validateFeedData(feed);
    }

    function test_RevertIfFeedIsNotConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.FeedNotConfigured.selector,
                feed
            )
        );
        oracle.exposed_validateFeedData(feed);
    }

    function test_NoRevertIfFeedIsConfigured() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        oracle.workaround_setFeedData(
            feed,
            FeedData(feed, decimals, underlyingDecimals)
        );

        oracle.exposed_validateFeedData(feed);

        assertTrue(true, "Must not revert");
    }
}
