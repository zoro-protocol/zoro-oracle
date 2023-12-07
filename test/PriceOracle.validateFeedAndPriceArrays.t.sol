// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {BasePriceOracle} from "src/BasePriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidateFeedAndPriceArrays is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(address(this), msg.sender, msg.sender);
    }

    function test_RevertIfArrayLengthsDoNotMatch() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](1);
        feeds[0] = feed;

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1;
        prices[1] = 2;

        vm.expectRevert(
            abi.encodeWithSelector(
                BasePriceOracle.PricesDoNotMatchFeeds.selector,
                feeds.length,
                prices.length
            )
        );
        oracle.exposed_validateFeedAndPriceArrays(feeds, prices);
    }

    function test_DoNotRevertIfArrayLengthsMatch() public {
        address feedAddress1 = makeAddr("feed1");
        AggregatorV3Interface feed1 = AggregatorV3Interface(feedAddress1);

        address feedAddress2 = makeAddr("feed2");
        AggregatorV3Interface feed2 = AggregatorV3Interface(feedAddress2);

        AggregatorV3Interface[] memory feeds = new AggregatorV3Interface[](2);
        feeds[0] = feed1;
        feeds[1] = feed2;

        uint256[] memory prices = new uint256[](2);
        prices[0] = 1;
        prices[1] = 2;

        oracle.exposed_validateFeedAndPriceArrays(feeds, prices);

        assertTrue(true, "Must not revert");
    }
}
