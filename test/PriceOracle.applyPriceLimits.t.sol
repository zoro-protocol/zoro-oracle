// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ApplyPriceLimits is Test {
    using Math for uint256;

    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function testFuzz_PriceNeverMovesOutsideLimits(
        uint256 price,
        uint256 oldPrice
    ) public {
        vm.assume(oldPrice > 0);

        uint256 maxDeltaMantissa = 1e17; // 10%

        uint256 maxChange = oldPrice / 10;

        uint256 minPrice = oldPrice > maxChange ? oldPrice - maxChange : 0; // 10% loss
        uint256 maxPrice = oldPrice < type(uint256).max - maxChange
            ? oldPrice + maxChange // 10% gain
            : type(uint256).max;

        uint256 newPrice = oracle.exposed_applyPriceLimits(
            price,
            oldPrice,
            maxDeltaMantissa
        );

        // Price should never exceed the price limits
        uint256 expectedPrice = price.max(minPrice).min(maxPrice);

        assertEq(newPrice, expectedPrice);
    }

    function testFuzz_NoLimitIfOldPriceIsZero(uint256 price) public {
        uint256 oldPrice = 0;

        uint256 maxDeltaMantissa = 1e17; // 10%

        uint256 newPrice = oracle.exposed_applyPriceLimits(
            price,
            oldPrice,
            maxDeltaMantissa
        );

        // Price should never exceed the price limits
        uint256 expectedPrice = price;

        assertEq(newPrice, expectedPrice);
    }
}
