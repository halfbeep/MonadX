// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/OrderStorage.sol";
import "./MarketMatching.sol";
import "./StopLimitMatching.sol";

// ! beware reentrantCalls permitted !
contract Ordering is OrderMatching, StopLimitMatching {
    // The placeOrder function is abstracted and inherited from the OrderStorage contract
    function placeOrder(
        string calldata instrument,
        uint256 amount,
        uint256 price, // price for Limit or Stop-Limit orders
        uint256 stopPrice, // stop price for Stop-Limit orders
        bool isBuyOrder,
        OrderType orderType
    ) external override {
        // Validate that the price and quantity are greater than 0
        require(price >= 0, "Price must be greater than 0");
        require(stopPrice >= 0, "Price must be greater than 0");
        require(amount > 0, "Quantity must be greater than 0");
        if (orderType == OrderType.Market) {
            // For market orders, we directly match the order
            _insertOrder(msg.sender, instrument, amount, 0, 0, isBuyOrder, orderType);
            matchOrders(instrument);
        } else if (orderType == OrderType.Limit) {
            // For Limit orders, we directly insert the order into the order book
            _insertOrder(msg.sender, instrument, amount, price, stopPrice, isBuyOrder, orderType);
        } else if (orderType == OrderType.ImmediateOrCancel) {
            // Handle ImmediateOrCancel (IOC)
            uint256 remainingAmount = matchBestOrder(instrument, amount, price, isBuyOrder);

            if (remainingAmount > 0) {
                // Cancel the remaining amount if not fully filled
                emit OrderCancelled(msg.sender, nextOrderId);
            }
        } else if (orderType == OrderType.StopLimit) {
            // Handle Stop-Limit orders
            _insertOrder(msg.sender, instrument, amount, price, stopPrice, isBuyOrder, orderType);
        }
    }

    // The cancelOrder function is abstracted and inherited from the OrderStorage contract
    function cancelOrder(uint256 orderId) external override {
        _cancelOrder(orderId, msg.sender);
    }
}
