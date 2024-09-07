// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/OrderStorage.sol";
import "../event/OrderEvents.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract OrderMatching is ReentrancyGuard, OrderStorage {
    function matchOrders(string calldata instrument) public override nonReentrant {
        for (uint256 i = 1; i < nextOrderId; i++) {
            Order storage aOrder = orders[i];

            if (
                aOrder.isFilled || aOrder.isCancelled
                    || keccak256(abi.encodePacked(aOrder.instrument)) != keccak256(abi.encodePacked(instrument))
            ) {
                continue;
            }

            emit LogOrder("a", i, aOrder.isFilled, aOrder.isCancelled, aOrder.isBuyOrder, aOrder.amount, aOrder.price);

            for (uint256 j = i + 1; j < nextOrderId + 1; j++) {
                Order storage bOrder = orders[j];

                if (
                    bOrder.isFilled || bOrder.isCancelled || bOrder.isBuyOrder == aOrder.isBuyOrder
                        || keccak256(abi.encodePacked(bOrder.instrument)) != keccak256(abi.encodePacked(instrument))
                ) {
                    continue;
                }

                emit LogOrder(
                    "b", j, bOrder.isFilled, bOrder.isCancelled, bOrder.isBuyOrder, bOrder.amount, bOrder.price
                );

                // Check if aOrder and bOrder can be matched
                bool matched = (!aOrder.isBuyOrder && aOrder.price >= bOrder.price)
                    || (aOrder.isBuyOrder && bOrder.price <= aOrder.price);

                if (matched) {
                    uint256 matchedAmount = _min(aOrder.amount, bOrder.amount);

                    // Update the amounts for both buy and sell orders
                    if (aOrder.amount == matchedAmount) {
                        aOrder.isFilled = true;
                        aOrder.amount = 0;
                    } else {
                        aOrder.amount -= matchedAmount;
                    }

                    if (bOrder.amount == matchedAmount) {
                        bOrder.isFilled = true;
                        bOrder.amount = 0;
                    } else {
                        bOrder.amount -= matchedAmount;
                    }

                    emit TradeMatched(aOrder.user, bOrder.user, instrument, matchedAmount, aOrder.price);

                    // Don't break here - continue matching other orders
                }

                // If both orders are fully filled, stop inner loop
                if (aOrder.amount == 0 || bOrder.amount == 0) {
                    break; // Exit the loop when one of the orders is fully filled
                }
            }
        }
    }

    // currently this isn't used for market orders
    function matchBestOrder(
        string calldata instrument,
        uint256 amount,
        uint256 price, // Added price parameter
        bool isBuyOrder
    ) public override nonReentrant returns (uint256) {
        uint256 remainingAmount = amount;

        for (uint256 i = 1; i <= nextOrderId; i++) {
            Order storage order = orders[i];

            emit LogSkipOrder(i, order.isFilled, order.isCancelled, order.isBuyOrder, order.amount, order.price);

            // Skip orders that are filled, cancelled, or of the same type (buy/sell)
            if (
                order.isFilled || order.isCancelled || order.isBuyOrder == isBuyOrder // Skip orders that are the same type (buy/buy or sell/sell)
                    || keccak256(abi.encodePacked(order.instrument)) != keccak256(abi.encodePacked(instrument))
            ) {
                continue;
            }

            // Match the order if it's a buy matching a sell or a sell matching a buy
            bool isValidMatch = isBuyOrder
                ? order.price <= price // Buy order wants lower/equal price
                : order.price >= price; // Sell order wants higher/equal price

            if (!isValidMatch) {
                continue;
            }

            // Match as much of the order as possible
            uint256 matchedAmount = _min(order.amount, remainingAmount);

            // Perform the trade and update order amounts
            order.amount -= matchedAmount;
            remainingAmount -= matchedAmount;

            if (order.amount == 0) {
                order.isFilled = true;
            }

            emit TradeMatched(order.user, msg.sender, instrument, matchedAmount, order.price);

            // Exit if the order is fully matched
            if (remainingAmount == 0) {
                return remainingAmount;
            }
        }

        return remainingAmount; // Return any unmatched amount
    }
}
