// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {CToken} from "@zoro-protocol/CToken.sol";
import {FeedData} from "/IFeedRegistry.sol";
import {PriceIsStale} from "/PriceOracle.sol";
import {PriceOracleHarness as PriceOracle} from "/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ValidateLiveness is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle();
    }

    function test_RevertIfPriceIsStale() public {
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

    function test_NoRevertIfPriceIsLive() public {
        CToken cToken = CToken(address(0));
        uint256 livePeriod = 12 hours;
        uint256 maxDeltaMantissa = 1e17; // 10%
        FeedData memory fd = FeedData(cToken, livePeriod, maxDeltaMantissa);

        uint256 timestamp = block.timestamp;

        oracle.exposed_validateLiveness(fd, timestamp);

        assertTrue(true, "Must not revert");
    }
}
