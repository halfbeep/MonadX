// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOrdering {
    enum OrderType {
        Limit,
        Market,
        Stop,
        StopLimit,
        FillOrKill,
        ImmediateOrCancel
    }

    function getOrder(uint256 orderId)
        external
        view
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
        );

    function placeOrder(
        string calldata instrument,
        uint256 amount,
        uint256 price, // price for Limit or Stop-Limit orders
        uint256 stopPrice, // stop price for Stop-Limit orders
        bool isBuyOrder,
        OrderType orderType
    ) external;

    function matchOrders(string calldata instrument) external;

    function matchBestOrder(string calldata instrument, uint256 amount, uint256 price, bool isBuyOrder)
        external
        returns (uint256);

    function cancelOrder(uint256 orderId) external;
}
