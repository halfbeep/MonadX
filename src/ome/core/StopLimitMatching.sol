// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/OrderStorage.sol";
import "../event/OrderEvents.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract StopLimitMatching is ReentrancyGuard, OrderStorage {
    // Check if stop-limit orders can be triggered and converted to limit orders
    function triggerStopLimitOrders(string calldata instrument, uint256 currentMarketPrice) external nonReentrant {
        for (uint256 i = 1; i <= nextOrderId; i++) {
            Order storage order = orders[i];

            // Check if the order is a StopLimit order and not filled or cancelled
            if (
                order.orderType == OrderType.StopLimit && !order.isFilled && !order.isCancelled
                    && keccak256(abi.encodePacked(order.instrument)) == keccak256(abi.encodePacked(instrument))
            ) {
                if (
                    (order.isBuyOrder && currentMarketPrice >= order.stopPrice) // Buy StopLimit triggered
                        || (!order.isBuyOrder && currentMarketPrice <= order.stopPrice) // Sell StopLimit triggered
                ) {
                    // Trigger the stop-limit order and convert it into a limit order
                    emit OrderTriggered(order.user, order.stopPrice, order.price, order.amount, order.instrument);
                    _convertStopLimitToLimit(i);
                }
            }
        }
    }

    // Convert a StopLimit order to a Limit order after being triggered
    function _convertStopLimitToLimit(uint256 orderId) internal {
        Order storage order = orders[orderId];
        order.orderType = OrderType.Limit; // Change the order type to Limit
    }
}
