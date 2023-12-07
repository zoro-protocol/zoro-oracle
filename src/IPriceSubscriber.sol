// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.18;

//  __  /   _ \  _ \   _ \     _ \ _ \   _ \ __ __| _ \   __|   _ \  |
//     /   (   |   /  (   |    __/   /  (   |   |  (   | (     (   | |
//  ____| \___/ _|_\ \___/    _|  _|_\ \___/   _| \___/ \___| \___/ ____|

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @author Zoro Protocol
 * @notice Subscribe to a publisher that pushes prices from Chainlink data feeds
 */
interface IPriceSubscriber {
    function setFeedPrice(AggregatorV3Interface feed, uint256 price) external;

    function setFeedPrices(
        AggregatorV3Interface[] calldata feeds,
        uint256[] calldata prices
    ) external;

    function getFeedPrices(AggregatorV3Interface[] calldata feeds)
        external
        view
        returns (uint256[] memory);
}
