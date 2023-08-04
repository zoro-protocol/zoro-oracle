// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Math} from "lib/openzeppelin-contracts/contracts/utils/math/Math.sol";
import {PriceOracleHarness as PriceOracle} from "src/PriceOracleHarness.sol";
import {Test} from "forge-std/Test.sol";

contract ConvertDecimalsForComptroller is Test {
    using Math for uint256;

    PriceOracle public oracle;

    function setUp() public {
        oracle = new PriceOracle(msg.sender, msg.sender, msg.sender);
    }

    function test_ZeroWhenValueIsTooSmall() public {
        uint256 value = 100 * 1e8;
        uint256 decimals = 75; // Use a lot of decimals to make `value` tiny
        uint256 underlyingDecimals = 18;

        uint256 convertedValue = oracle.exposed_convertDecimalsForComptroller(
            value,
            decimals,
            underlyingDecimals
        );

        uint256 expected = 0;
        assertEq(convertedValue, expected);
    }

    function test_ConvertWhenUnderlyingDecimalsIsZero() public {
        uint256 value = 100 * 1e8;
        uint256 decimals = 8;
        uint256 underlyingDecimals = 0;

        uint256 convertedValue = oracle.exposed_convertDecimalsForComptroller(
            value,
            decimals,
            underlyingDecimals
        );

        uint256 expected = 100 * 1e36;
        assertEq(convertedValue, expected);
    }

    function testFuzz_ConvertToPriceMantissaDecimals(
        uint8 decimals,
        uint8 underlyingDecimals
    ) public {
        uint256 TEST_PRICE_DIGITS = 8;
        uint256 value = 10**TEST_PRICE_DIGITS;

        uint256 convertedValue = oracle.exposed_convertDecimalsForComptroller(
            value,
            decimals,
            underlyingDecimals
        );

        uint256 totalDecimals = uint256(decimals) + uint256(underlyingDecimals);
        uint256 priceMantissaDecimals = oracle.PRICE_MANTISSA_DECIMALS();

        // If `value` is 1e8 and the decimals are above price mantissa decimals,
        // then it should always return zero, because `value` is too small for
        // the price mantissa's precision.
        uint256 expected = 0;

        // E.g. `decimals = 8, underlyingDecimals = 18`:
        // `price * 1e(36 - 8) / 1e18`
        if (totalDecimals <= priceMantissaDecimals + TEST_PRICE_DIGITS) {
            uint256 priceMantissaBase = 10**priceMantissaDecimals;
            uint256 decimalsBase = 10**decimals;
            uint256 underlyingDecimalsBase = 10**underlyingDecimals;

            expected =
                value.mulDiv(priceMantissaBase, decimalsBase) /
                underlyingDecimalsBase;
        }

        assertEq(convertedValue, expected);
    }
}
