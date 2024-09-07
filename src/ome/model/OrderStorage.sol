// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/IOrdering.sol";
import "../event/OrderEvents.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract OrderStorage is IOrdering, ReentrancyGuard, OrderEvents {
    struct Order {
        uint256 orderId;
        address user;
        string instrument;
        uint256 amount;
        uint256 price;
        uint256 stopPrice; // Used for Stop and StopLimit orders
        bool isBuyOrder;
        bool isFilled;
        bool isCancelled;
        OrderType orderType;
    }

    mapping(uint256 => Order) public orders;
    uint256 public nextOrderId;

    function getOrder(uint256 orderId)
        external
        view
        override
        returns (
            uint256 _orderId,
            address user,
            string memory instrument,
            uint256 amount,
            uint256 price,
            uint256 stopPrice,
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            OrderType orderType
        )
    {
        Order storage order = orders[orderId];
        return (
            order.orderId,
            order.user,
            order.instrument,
            order.amount,
            order.price,
            order.stopPrice,
            order.isBuyOrder,
            order.isFilled,
            order.isCancelled,
            order.orderType
        );
    }

    // Insert or update an order in the mapping
    function _insertOrder(
        address user,
        string memory instrument,
        uint256 amount,
        uint256 price,
        uint256 stopPrice,
        bool isBuyOrder,
        OrderType orderType
    ) internal nonReentrant returns (uint256) {
        nextOrderId++;

        uint256 insertIndex = nextOrderId;

        // Find the correct insertion point based on price
        for (uint256 i = 1; i < nextOrderId; i++) {
            Order storage existingOrder = orders[i];

            // For buy orders, sort by descending price
            if (isBuyOrder && existingOrder.isBuyOrder && price > existingOrder.price) {
                insertIndex = i;
                break;
            }

            // For sell orders, sort by ascending price
            if (!isBuyOrder && !existingOrder.isBuyOrder && price < existingOrder.price) {
                insertIndex = i;
                break;
            }
        }

        // Shift existing orders to make room for the new order
        for (uint256 i = nextOrderId; i > insertIndex; i--) {
            orders[i] = orders[i - 1];
        }

        // Insert the new order at the correct position
        orders[insertIndex] = Order({
            orderId: nextOrderId,
            user: user,
            instrument: instrument,
            amount: amount,
            price: price,
            stopPrice: stopPrice, // stopPrice for Stop and StopLimit orders
            isBuyOrder: isBuyOrder,
            isFilled: false,
            isCancelled: false,
            orderType: orderType
        });

        emit OrderPlaced(user, nextOrderId, instrument, amount, price, stopPrice, isBuyOrder, orderType);

        return nextOrderId;
    }

    // Helper function to cancel an order
    function _cancelOrder(uint256 orderId, address user) internal nonReentrant {
        Order storage order = orders[orderId];
        emit LogCancel(order.user, user);
        require(order.user == user, "Only the owner can cancel the order");
        require(!order.isFilled, "Order already filled");
        require(!order.isCancelled, "Order already cancelled");

        order.isCancelled = true;
        emit OrderCancelled(user, orderId);
    }

    // Helper function to find the minimum of two numbers
    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
