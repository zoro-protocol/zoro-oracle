// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import "/PriceOracle.sol";
import {PriceData} from "/IPriceReceiver.sol";

contract PriceOracleHarness is PriceOracle {
    function exposed_validateTimestamp(PriceData memory pd, uint256 timestamp)
        external
        pure
    {
        _validateTimestamp(pd, timestamp);
    }

    function exposed_calculateDeltaMantissa(uint256 oldPrice, uint256 newPrice)
        external
        pure
        returns (uint256)
    {
        return _calculateDeltaMantissa(oldPrice, newPrice);
    }

    function exposed_useDefault(uint256 value, uint256 defaultValue)
        external
        pure
        returns (uint256)
    {
        return _useDefault(value, defaultValue);
    }
}
