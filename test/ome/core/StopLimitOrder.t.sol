// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol";
import "../../../src/ome/core/Ordering.sol";

contract StopLimitOrderTest is Test {
    Ordering matchingAlgorithm;

    function setUp() public {
        matchingAlgorithm = new Ordering();
    }

    // Test Stop-Limit Buy Order
    function testStopLimitBuyOrder() public {
        // Place a sell limit order
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, false, IOrdering.OrderType.Limit); // Sell 100 ETH at $2000

        // Place a stop-limit buy order (trigger at $1950, limit at $1900)
        matchingAlgorithm.placeOrder(
            "ETH/USD",
            100,
            1900, // Limit price
            1950, // Stop price
            true, // Is Buy Order
            IOrdering.OrderType.StopLimit
        );

        // Check that the order exists but is not yet triggered
        (
            ,
            ,
            ,
            uint256 amount,
            uint256 price,
            uint256 stopPrice,
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            IOrdering.OrderType orderType
        ) = matchingAlgorithm.getOrder(2);

        assertEq(amount, 100);
        assertEq(price, 1900); // Limit price
        assertEq(stopPrice, 1950); // Stop price
        assertTrue(isBuyOrder);
        assertFalse(isFilled);
        assertFalse(isCancelled);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.StopLimit));

        // Simulate the market price reaching the stop price
        matchingAlgorithm.triggerStopLimitOrders("ETH/USD", 1951);

        // Check that the stop-limit order is now converted to a limit order
        (,,, amount, price, stopPrice, isBuyOrder, isFilled, isCancelled, orderType) = matchingAlgorithm.getOrder(2);

        assertEq(amount, 100);
        assertEq(price, 1900); // Limit price remains the same
        assertEq(stopPrice, 1950); // stop price becomes zero
        assertTrue(isBuyOrder);
        assertFalse(isFilled);
        assertFalse(isCancelled);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.Limit)); // Now a Limit Order
    }

    // Test Stop-Limit Sell Order
    function testStopLimitSellOrder() public {
        // Place a buy limit order
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, true, IOrdering.OrderType.Limit); // Buy 100 ETH at $2000

        // PlOrderingsell order (trigger at $2050, limit at $2100)
        matchingAlgorithm.placeOrder(
            "ETH/USD",
            100,
            2100, // Limit price
            2050, // Stop price
            false, // Is Sell Order
            IOrdering.OrderType.StopLimit
        );

        // Check that the stop-limit sell order is created but not yet triggered
        (
            ,
            ,
            ,
            uint256 amount,
            uint256 price,
            uint256 stopPrice,
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            IOrdering.OrderType orderType
        ) = matchingAlgorithm.getOrder(2);

        assertEq(amount, 100);
        assertEq(price, 2100); // Limit price
        assertFalse(isBuyOrder);
        assertFalse(isFilled);
        assertFalse(isCancelled);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.StopLimit));

        // Simulate the market price reaching the stop price
        matchingAlgorithm.triggerStopLimitOrders("ETH/USD", 2050);

        // Check that the stop-limit order is now converted to a limit order
        (,,, amount, price, stopPrice, isBuyOrder, isFilled, isCancelled, orderType) = matchingAlgorithm.getOrder(2);

        assertEq(amount, 100);
        assertEq(price, 2100); // Limit price remains the same
        assertFalse(isBuyOrder); // Sell order
        assertFalse(isFilled);
        assertFalse(isCancelled);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.Limit)); // Now a Limit Order
    }

    // Test triggering multiple Stop-Limit orders
    function testTriggerMultipleStopLimitOrders() public {
        // Place multiple stop-limit orders
        matchingAlgorithm.placeOrder(
            "ETH/USD",
            100,
            1950, // Limit price
            1900, // Stop price
            true, // Buy Order
            IOrdering.OrderType.StopLimit
        ); // Buy 100 ETH at $1900, triggered at $1950

        matchingAlgorithm.placeOrder(
            "ETH/USD",
            150,
            2050, // Limit price
            2100, // Stop price
            false, // Sell Order
            IOrdering.OrderType.StopLimit
        ); // Sell 150 ETH at $2100, triggered at $2050

        // Simulate the market price reaching the stop prices
        matchingAlgorithm.triggerStopLimitOrders("ETH/USD", 2050); // This should trigger both orders

        // Check that the first stop-limit order is now converted to a limit order
        (
            ,
            ,
            ,
            uint256 amount1,
            uint256 price1,
            ,
            bool isBuyOrder1,
            bool isFilled1,
            bool isCancelled1,
            IOrdering.OrderType orderType1
        ) = matchingAlgorithm.getOrder(1);

        assertEq(amount1, 100);
        assertEq(price1, 1950); // Limit price
        assertTrue(isBuyOrder1);
        assertFalse(isFilled1);
        assertFalse(isCancelled1);
        assertEq(uint256(orderType1), uint256(IOrdering.OrderType.Limit));

        // Check that the second stop-limit order is now converted to a limit order
        (
            ,
            ,
            ,
            uint256 amount2,
            uint256 price2,
            ,
            bool isBuyOrder2,
            bool isFilled2,
            bool isCancelled2,
            IOrdering.OrderType orderType2
        ) = matchingAlgorithm.getOrder(2);

        assertEq(amount2, 150);
        assertEq(price2, 2050); // Limit price
        assertFalse(isBuyOrder2); // Sell order
        assertFalse(isFilled2);
        assertFalse(isCancelled2);
        assertEq(uint256(orderType2), uint256(IOrdering.OrderType.Limit));
    }

    // Test that Stop-Limit orders are not triggered when market conditions are not met
    function testStopLimitOrderNotTriggered() public {
        // Place a stop-limit buy order (trigger at $1950, limit at $1900)
        matchingAlgorithm.placeOrder(
            "ETH/USD",
            100,
            1950, // Limit price
            1900, // StopPrice price
            true, // Buy Order
            IOrdering.OrderType.StopLimit
        );

        // Simulate the market price not reaching the stop price
        matchingAlgorithm.triggerStopLimitOrders("ETH/USD", 1800); // Should not trigger

        // Check that the order remains as a stop-limit order and is not converted
        (
            ,
            ,
            ,
            uint256 amount,
            uint256 price,
            ,
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            IOrdering.OrderType orderType
        ) = matchingAlgorithm.getOrder(1);

        assertEq(amount, 100);
        assertEq(price, 1950); // Limit price
        assertTrue(isBuyOrder);
        assertFalse(isFilled);
        assertFalse(isCancelled);
        assertEq(uint256(orderType), uint256(IOrdering.OrderType.StopLimit)); // Still a StopLimit order
    }
}
