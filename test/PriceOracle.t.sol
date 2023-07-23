// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {CToken} from "@zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {FeedNotConfigured, InvalidAddress, InvalidTimestamp, PriceData, PriceIsStale} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
    }

    function test_validateTimestamp_noRevertIfNew() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 oldPrice = 1e18;
        uint256 oldTimestamp = block.timestamp;
        PriceData memory pd = PriceData(feed, oldPrice, oldTimestamp);

        uint256 newTimestamp = block.timestamp + 1 days;

        oracle.exposed_validateTimestamp(pd, newTimestamp);

        assertTrue(true, "Must not revert");
    }

    function test_validateTimestamp_revertIfOld() public {
        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 oldPrice = 1e18;
        uint256 oldTimestamp = block.timestamp + 1 days;
        PriceData memory pd = PriceData(feed, oldPrice, oldTimestamp);

        uint256 newTimestamp = block.timestamp;

        vm.expectRevert(
            abi.encodeWithSelector(InvalidTimestamp.selector, newTimestamp)
        );
        oracle.exposed_validateTimestamp(pd, newTimestamp);
    }

    function test_calculateDeltaMantissa_zeroIfNoPriceChange() public {
        uint256 expectedDelta = 0;

        uint256 oldPrice = 100;
        uint256 newPrice = 100;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        assertEq(deltaMantissa, expectedDelta);
    }

    function test_calculateDeltaMantissa_positiveDeltaWhenNegativeChange()
        public
    {
        uint256 oldPrice = 100;
        uint256 newPrice = 90;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        uint256 expected = 1 * 1e17; // 10%
        assertEq(deltaMantissa, expected);
    }

    function test_calculateDeltaMantissa_positiveDeltaWhenPositiveChange()
        public
    {
        uint256 oldPrice = 100;
        uint256 newPrice = 110;

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            newPrice
        );

        uint256 expected = 1e17; // 10%
        assertEq(deltaMantissa, expected);
    }

    function test_useDefault_defaultIfZero() public {
        uint256 value = 0;
        uint256 defaultValue = type(uint256).max;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = defaultValue;
        assertEq(result, expected);
    }

    function test_useDefault_valueIfGtZero() public {
        uint256 value = 10;
        uint256 defaultValue = type(uint256).max;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = value;
        assertEq(result, expected);
    }

    function test_useDefault_zeroIfBothZero() public {
        uint256 value = 0;
        uint256 defaultValue = 0;

        uint256 result = oracle.exposed_useDefault(value, defaultValue);

        uint256 expected = 0;
        assertEq(result, expected);
    }

    function test_validateAddress_revertIfAddressIsZero() public {
        address addr = address(0);

        vm.expectRevert(InvalidAddress.selector);
        oracle.exposed_validateAddress(addr);
    }

    function test_validateAddress_noRevertIfAddressIsNonZero() public {
        address addr = address(oracle);

        oracle.exposed_validateAddress(addr);

        assertTrue(true, "Must not revert");
    }

    function test_validateLiveness_revertIfPriceIsStale() public {
        CToken cToken = CToken(address(0));
        uint256 livePeriod = 12 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(cToken, livePeriod, maxDeltaMantissa);

        uint256 timestamp = block.timestamp;
        skip(livePeriod + 1); // Must be past the live period

        vm.expectRevert(
            abi.encodeWithSelector(PriceIsStale.selector, timestamp)
        );
        oracle.exposed_validateLiveness(fd, timestamp);
    }

    function test_validateLiveness_noRevertIfPriceIsLive() public {
        CToken cToken = CToken(address(0));
        uint256 livePeriod = 12 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(cToken, livePeriod, maxDeltaMantissa);

        uint256 timestamp = block.timestamp;

        oracle.exposed_validateLiveness(fd, timestamp);

        assertTrue(true, "Must not revert");
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
