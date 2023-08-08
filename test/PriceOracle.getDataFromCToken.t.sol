// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "zoro-protocol/contracts/CToken.sol";
import {FeedData} from "src/IFeedRegistry.sol";
import {PriceData} from "src/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract GetDataFromCToken is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_EmptyFeedIfCTokenHasNoFeed() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 price = 1e8; // $1 (8 decimals)
        oracle.workaround_setPriceData(cToken, PriceData(feed, price));

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromCToken(cToken);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);

        assertEq(address(fd.cToken), address(0));
    }

    function test_ReturnPriceDataAndFeedData() public {
        address feedAddress = makeAddr("feed");
        AggregatorV3Interface feed = AggregatorV3Interface(feedAddress);

        address cTokenAddress = makeAddr("cToken");
        CToken cToken = CToken(cTokenAddress);

        uint256 decimals = 8;
        uint256 underlyingDecimals = 18;
        oracle.workaround_setFeedData(
            feed,
            FeedData(cToken, decimals, underlyingDecimals)
        );

        uint256 price = 1e8; // $1 (8 decimals)
        oracle.workaround_setPriceData(cToken, PriceData(feed, price));

        (PriceData memory pd, FeedData memory fd) = oracle
            .exposed_getDataFromCToken(cToken);

        assertEq(address(pd.feed), feedAddress);
        assertEq(pd.price, price);

        assertEq(address(fd.cToken), cTokenAddress);
    }
}
