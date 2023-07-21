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
}
