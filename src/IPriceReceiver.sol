// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.10;

import {CToken} from "@zoro-protocol/CToken.sol";

interface IPriceReceiver {
    struct Data {
        uint256 price;
        uint256 timestamp;
    }

    function setUnderlyingPrice(
        CToken cToken,
        uint256 price,
        uint256 timestamp
    ) external;
}
