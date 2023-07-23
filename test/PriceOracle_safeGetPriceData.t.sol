// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "chainlink/contracts/interfaces/AggregatorV3Interface.sol";
import {CToken} from "@zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {PriceData, PriceNotSet} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract PriceOracleTest is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
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
}
