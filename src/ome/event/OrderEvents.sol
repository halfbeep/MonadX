// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../core/IOrdering.sol";

abstract contract OrderEvents is IOrdering {
    event OrderTriggered(
        address indexed user, uint256 stopPrice, uint256 limitPrice, uint256 amount, string instrument
    );

    event LogCancel(address orderUser, address msgSender);

    event LogOrder(
        string descp, uint256 ndx, bool isFilled, bool isCancelled, bool isBuyOrder, uint256 amount, uint256 price
    );

    event LogSkipOrder(uint256 ndx, bool isFilled, bool isCancelled, bool isBuyOrder, uint256 amount, uint256 price);

    event TradeMatched(address indexed maker, address indexed taker, string instrument, uint256 amount, uint256 price);
    event OrderPlaced(
        address indexed user,
        uint256 orderId,
        string instrument,
        uint256 amount,
        uint256 price,
        uint256 stopPrice,
        bool isBuyOrder,
        OrderType orderType
    );
    event OrderCancelled(address indexed user, uint256 orderId);
}
