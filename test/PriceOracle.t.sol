// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {CToken} from "@zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {FeedNotConfigured, InvalidAddress, InvalidTimestamp, PriceData, PriceNotSet, PriceIsStale} from "/PriceOracle.sol";
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

    function test_safeGetPriceData_revertIfPriceDataNotSet() public {
        CToken cToken = CToken(address(0));

        vm.expectRevert(abi.encodeWithSelector(PriceNotSet.selector, cToken));
        oracle.exposed_safeGetPriceData(cToken);
    }

    function test_safeGetPriceData_revertIfFeedNotSet() public {
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        AggregatorV3Interface feed = AggregatorV3Interface(address(0));
        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        vm.expectRevert(abi.encodeWithSelector(PriceNotSet.selector, cToken));
        oracle.exposed_safeGetPriceData(cToken);
    }

    function test_safeGetPriceData_revertIfPriceIsZero() public {
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 price = 0;
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        vm.expectRevert(abi.encodeWithSelector(PriceNotSet.selector, cToken));
        oracle.exposed_safeGetPriceData(cToken);
    }

    function test_safeGetPriceData_returnPriceData() public {
        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);
        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        PriceData memory pd = oracle.exposed_safeGetPriceData(cToken);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);
        assertEq(pd.timestamp, timestamp);
    }

    function test_getDataFromFeed_emptyPriceIfFeedHasNoPrices() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(CToken(cTokenAddress), livePeriod, maxDeltaMantissa)
        );

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromFeed(feed);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);

        assertEq(address(pd.feed), address(0));
        assertEq(pd.price, 0);
        assertEq(pd.timestamp, 0);
    }

    function test_getDataFromFeed_returnPriceDataAndFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(cToken, livePeriod, maxDeltaMantissa)
        );

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromFeed(feed);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);
        assertEq(pd.timestamp, timestamp);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);
    }

    function test_getDataFromCToken_emptyFeedIfCTokenHasNoFeed() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromCToken(cToken);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);
        assertEq(pd.timestamp, timestamp);

        assertEq(address(fd.cToken), address(0));
        assertEq(fd.livePeriod, 0);
        assertEq(fd.maxDeltaMantissa, 0);
    }

    function test_getDataFromCToken_returnPriceDataAndFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 livePeriod = 24 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        oracle.workaround_setFeedData(
            feed,
            FeedData(cToken, livePeriod, maxDeltaMantissa)
        );

        uint256 price = 1e8; // $1 (8 decimals)
        uint256 timestamp = block.timestamp;
        oracle.workaround_setPriceData(
            cToken,
            PriceData(feed, price, timestamp)
        );

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromCToken(cToken);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);
        assertEq(pd.timestamp, timestamp);

        assertEq(address(fd.cToken), cTokenAddress);
        assertEq(fd.livePeriod, livePeriod);
        assertEq(fd.maxDeltaMantissa, maxDeltaMantissa);
    }
}
