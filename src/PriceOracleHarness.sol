// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import "/PriceOracle.sol";
import {PriceData} from "/IPriceReceiver.sol";
import {FeedData} from "/IFeedRegistry.sol";

contract PriceOracleHarness is PriceOracle {
    function exposed_validateLiveness(FeedData memory fd, uint256 timestamp)
        external
        view
    {
        _validateLiveness(fd, timestamp);
    }

    function exposed_validateAddress(address addr) external pure {
        _validateAddress(addr);
    }

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
