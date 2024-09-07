// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol"; // Importing Foundry's Test library
import "../../../src/ome/core/Ordering.sol"; // Path to your Ordering.sol

contract OrderingTest is Test {
    Ordering public matchingAlgorithm;

    // Users for testing
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        // Deploy the Ordering contract before each test
        matchingAlgorithm = new Ordering();
    }

    // Test: Placing a Limit Buy Order
    function testPlaceLimitBuyOrder() public {
        vm.startPrank(user1); // Simulate user1 calling the function
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, true, IOrdering.OrderType.Limit);
        vm.stopPrank();
        (
            ,
            /*uint256 orderId*/
            address user,
            string memory instrument,
            uint256 amount,
            uint256 price,
            ,
            /*uint256 stopPrice*/
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            IOrdering.OrderType orderType
        ) = matchingAlgorithm.orders(1);

        // Check if the order details are correctly stored
        assertEq(user, user1);
        assertEq(instrument, "ETH/USD");
        assertEq(amount, 100);
        assertEq(price, 2000);
        assertEq(isBuyOrder, true);
        assertEq(isFilled, false);
        assertEq(isCancelled, false);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.Limit));
    }

    // Test: Placing a Limit Sell Order
    function testPlaceLimitSellOrder() public {
        vm.startPrank(user2); // Simulate user2 calling the function
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, false, IOrdering.OrderType.Limit);
        vm.stopPrank();

        (
            ,
            /*uint256 orderId*/
            address user,
            string memory instrument,
            uint256 amount,
            uint256 price,
            ,
            /*uint256 stopPrice*/
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            IOrdering.OrderType orderType
        ) = matchingAlgorithm.orders(1);

        // Check if the order details are correctly stored
        assertEq(user, user2);
        assertEq(instrument, "ETH/USD");
        assertEq(amount, 100);
        assertEq(price, 2000);
        assertEq(isBuyOrder, false);
        assertEq(isFilled, false);
        assertEq(isCancelled, false);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.Limit));
    }

    // Test: Matching Buy and Sell Orders
    function testMatchOrders() public {
        // Place a buy order from user1
        vm.startPrank(user1);
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, true, IOrdering.OrderType.Limit);
        vm.stopPrank();

        // Place a sell order from user2
        vm.startPrank(user2);
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, false, IOrdering.OrderType.Limit);
        vm.stopPrank();

        // Match orders
        matchingAlgorithm.matchOrders("ETH/USD");

        // Fetch updated orders
        (,,, uint256 buyOrderAmount,,,, bool buyIsFilled,,) = matchingAlgorithm.orders(1);
        (,,, uint256 sellOrderAmount,,,, bool sellIsFilled,,) = matchingAlgorithm.orders(2);

        // Both orders should be fully filled
        assertEq(buyOrderAmount, 0); // Amount should be 0 after matching
        assertEq(sellOrderAmount, 0); // Amount should be 0 after matching
        assertEq(buyIsFilled, true); // Buy order should be filled
        assertEq(sellIsFilled, true); // Sell order should be filled
    }

    event LogCancel(address orderUser, address msgSender);
    // Test: Cancelling an Order

    function testCancelOrderWithLogs() public {
        // Simulate placing an order from user1
        vm.startPrank(address(0x0000000000000000000000000000000000000001));
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, true, IOrdering.OrderType.Limit);
        vm.stopPrank();

        // Log the order owner and msg.sender before cancellation
        vm.expectEmit(true, true, false, true);
        emit LogCancel(
            address(0x0000000000000000000000000000000000000001), address(0x0000000000000000000000000000000000000001)
        );

        // Attempt to cancel the order from the same user
        vm.startPrank(address(0x0000000000000000000000000000000000000001));
        matchingAlgorithm.cancelOrder(1); // Ensure to use the correct order ID (1)
        vm.stopPrank();
    }

    // Test: Order Should Not Be Matched If Cancelled
    function testOrderShouldNotMatchIfCancelled() public {
        // Place a buy order from user1
        vm.startPrank(user1);
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, true, IOrdering.OrderType.Limit);
        vm.stopPrank();

        // Place a sell order from user2
        vm.startPrank(user2);
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, false, IOrdering.OrderType.Limit);
        vm.stopPrank();

        // Cancel the buy order
        vm.startPrank(user1);
        matchingAlgorithm.cancelOrder(1);
        vm.stopPrank();

        // Try to match orders
        matchingAlgorithm.matchOrders("ETH/USD");

        // Buy order should remain cancelled and not matched
        (,,, uint256 buyOrderAmount,,,, bool buyIsFilled, bool buyIsCancelled,) = matchingAlgorithm.orders(1);
        (,,, uint256 sellOrderAmount,,,, bool sellIsFilled,,) = matchingAlgorithm.orders(2);

        assertEq(buyOrderAmount, 100); // Unchanged
        assertEq(sellOrderAmount, 100); // Unchanged
        assertEq(buyIsFilled, false); // Not filled
        assertEq(buyIsCancelled, true); // Cancelled
        assertEq(sellIsFilled, false); // Not filled
    }
}
