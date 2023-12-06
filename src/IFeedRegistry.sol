// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

//  __  /   _ \  _ \   _ \     _ \ _ \   _ \ __ __| _ \   __|   _ \  |
//     /   (   |   /  (   |    __/   /  (   |   |  (   | (     (   | |
//  ____| \___/ _|_\ \___/    _|  _|_\ \___/   _| \___/ \___| \___/ ____|

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {CToken} from "lib/zoro-protocol/contracts/CToken.sol";

/**
 * @notice Configuration for a feed used by the oracle
 */
struct Feed {
    // `feed` is checked to verify a struct is initialized
    // Decimals can be zero, so they are unreliable for this check
    AggregatorV3Interface feed;
    uint256 decimals;
    uint256 underlyingDecimals;
}

/**
 * @author Zoro Protocol
 * @notice Manage a registry of feeds used by an oracle
 * @notice Configure a feed to add it to the registry
 */
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
