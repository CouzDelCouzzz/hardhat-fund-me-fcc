// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    // We need the price of the native token. To do so, we will use Chainlink.
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // We need: -> ABI
        // We will use the Interface of the contract. We will import it from Github

        // We need: -> Address of the contract -> we can get it from the chainlink website -> https://docs.chain.link/data-feeds/price-feeds/addresses
        // 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e

        (, int256 price, , , ) = priceFeed.latestRoundData(); // Will get the ETH price in terms of USD with 8 decimals

        return uint256(price * 1e10); // To match with msg.value decimals and variable type
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;

        return ethAmountInUsd;
    }
}
