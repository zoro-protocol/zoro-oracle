// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "lib/zoro-protocol/contracts/CToken.sol";


struct Feed {
    // Checked to make sure the feed data is set even when decimals are zero
    AggregatorV3Interface feed;
    uint256 decimals;
    uint256 underlyingDecimals;
}

interface IFeedRegistry {
    function configureFeed(
        AggregatorV3Interface feed,
        uint256 decimals,
        uint256 underlyingDecimals
    ) external;

    function connectCTokenToFeed(CToken cToken, AggregatorV3Interface feed)
        external;

    function connectedFeeds(CToken)
        external
        view
        returns (AggregatorV3Interface);

    function getFeedAddresses() external view returns (address[] memory);
}
