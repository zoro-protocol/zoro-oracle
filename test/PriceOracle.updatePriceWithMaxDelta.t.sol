// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract UpdatePriceWithMaxDelta is Test {
    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function testFuzz_LimitPriceGainToMaxDelta(uint256 price) public {
        uint256 oldPrice = 1e8; // $1 (8 decimals)
        uint256 maxDeltaMantissa = 1e17; // 10%
        uint256 maxPrice = 11 * 1e7; // $1.10 (10% gain)

        // Price change is over the default max delta
        vm.assume(price > maxPrice);

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            price
        );

        uint256 newPrice = oracle.exposed_updatePriceWithMaxDelta(
            price,
            oldPrice,
            deltaMantissa,
            maxDeltaMantissa
        );

        uint256 expectedPrice = maxPrice; // 10% increase
        assertEq(newPrice, expectedPrice);
    }

    function testFuzz_LimitPriceLossToMaxDelta(uint256 price) public {
        uint256 oldPrice = 1e8; // $1 (8 decimals)
        uint256 maxDeltaMantissa = 1e17; // 10%
        uint256 minPrice = 9 * 1e7; // $0.90 (10% loss)

        // Price change is over the default max delta
        vm.assume(price < minPrice);

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            price
        );

        uint256 newPrice = oracle.exposed_updatePriceWithMaxDelta(
            price,
            oldPrice,
            deltaMantissa,
            maxDeltaMantissa
        );

        uint256 expectedPrice = minPrice; // 10% decrease
        assertEq(newPrice, expectedPrice);
    }

    function testFuzz_NoLimitIfDeltaIsLessThanMax(uint256 price) public {
        uint256 oldPrice = 1e8; // $1 (8 decimals)
        uint256 maxDeltaMantissa = 1e17; // 10%
        uint256 minPrice = 9 * 1e7; // $0.90 (10% loss)
        uint256 maxPrice = 11 * 1e7; // $1.10 (10% gain)

        // Price change is over the default max delta
        price = bound(price, minPrice, maxPrice);

        uint256 deltaMantissa = oracle.exposed_calculateDeltaMantissa(
            oldPrice,
            price
        );

        uint256 newPrice = oracle.exposed_updatePriceWithMaxDelta(
            price,
            oldPrice,
            deltaMantissa,
            maxDeltaMantissa
        );

        uint256 expectedPrice = price;
        assertEq(newPrice, expectedPrice);
    }
}
