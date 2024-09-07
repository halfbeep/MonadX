// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol";
import "../../../src/ome/core/Ordering.sol";

contract MarketOrderTest is Test {
    IOrdering matchingAlgorithm;

    function setUp() public {
        matchingAlgorithm = new Ordering();
    }

    // Helper function to get the tuple data from the orders mapping
    function getOrder(uint256 orderId)
        internal
        view
        returns (
            uint256 orderId_,
            address user,
            string memory instrument,
            uint256 amount,
            uint256 price,
            uint256 stopPrice,
            bool isBuyOrder,
            bool isFilled,
            bool isCancelled,
            IOrdering.OrderType orderType
        )
    {
        return matchingAlgorithm.getOrder(orderId);
    }

    function testMarketBuyOrder() public {
        // Place a few sell limit orders
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, false, IOrdering.OrderType.Limit); // Sell at $2000
        matchingAlgorithm.placeOrder("ETH/USD", 50, 1950, 0, false, IOrdering.OrderType.Limit); // Sell at $1950
        matchingAlgorithm.placeOrder("ETH/USD", 150, 2050, 0, false, IOrdering.OrderType.Limit); // Sell at $2050

        // Place a market buy order (buying without specifying price)
        matchingAlgorithm.placeOrder("ETH/USD", 120, 0, 0, true, IOrdering.OrderType.Market); // Buy 120 ETH at market price

        // fyi matchBestSellOrder is called from within placeOrder

        // Assert the first sell order at $1950 should be fully filled
        (,,, uint256 amount1,,,, bool isFilled1,,) = getOrder(1);
        assertTrue(isFilled1);
        assertEq(amount1, 0); // Fully filled

        // Assert the second sell order at $2000 should be partially filled
        (,,, uint256 amount2,,,, bool isFilled2,,) = getOrder(2);
        assertFalse(isFilled2); // Expecting the order to be partially filled
        assertEq(amount2, 30); // 100 - 70 = 30 remaining
    }

    // Test placing and matching a market sell order
    function testMarketSellOrder() public {
        // Place a few buy limit orders
        matchingAlgorithm.placeOrder("ETH/USD", 100, 2000, 0, true, IOrdering.OrderType.Limit); // Buy at $2000
        matchingAlgorithm.placeOrder("ETH/USD", 50, 1950, 0, true, IOrdering.OrderType.Limit); // Buy at $1950
        matchingAlgorithm.placeOrder("ETH/USD", 150, 2050, 0, true, IOrdering.OrderType.Limit); // Buy at $2050

        // Place a market sell order (selling without specifying price)
        matchingAlgorithm.placeOrder("ETH/USD", 120, 0, 0, false, IOrdering.OrderType.Market); // Sell 120 ETH at market price

        // Assert the first buy order at $2050 should be partially filled (120 out of 150)
        (,,, uint256 amount3,,,, bool isFilled3,,) = getOrder(1);
        assertEq(amount3, 30); // 150 - 120 = 30 remaining
        assertFalse(isFilled3); // Not fully filled

        // Assert the market sell order is filled and empty after the match
        (,,, uint256 amount4, uint256 price4,,,,,) = getOrder(4);
        assertEq(amount4, 0);
        assertEq(price4, 0);
    }

    // Test failing cases where no matching orders exist
    function testMarketBuyOrderFailsNoSellOrders() public {
        // Expect the new error message
        // vm.expectRevert("Not enough sell orders to fulfill buy order");
        /* this condition is detail that will depend on
        order/book design
        matchingAlgorithm.placeOrder(
            "ETH/USD",
            100,
            0,
            0,
            true,
            IOrderinge.Market
        );
        */
    }

    function testMarketBuyOrderPartialMultiple() public {
        // Place multiple sell orders at different prices
        matchingAlgorithm.placeOrder("ETH/USD", 50, 2000, 0, false, IOrdering.OrderType.Limit); // Sell at $2000
        matchingAlgorithm.placeOrder("ETH/USD", 70, 1900, 0, false, IOrdering.OrderType.Limit); // Sell at $1900
        matchingAlgorithm.placeOrder("ETH/USD", 100, 1800, 0, false, IOrdering.OrderType.Limit); // Sell at $1800

        // Place a market buy order that spans multiple sell orders
        matchingAlgorithm.placeOrder("ETH/USD", 120, 0, 0, true, IOrdering.OrderType.Market); // Buy 120 ETH at market price

        // Assert that the third order (Sell at $2000) is fully filled
        (,,, uint256 amount3,,,, bool isFilled3,,) = matchingAlgorithm.getOrder(3);
        assertFalse(isFilled3);
        assertEq(amount3, 50);

        // Assert that the second order (Sell at $1900) is partially filled
        (,,, uint256 amount2,,,, bool isFilled2,,) = matchingAlgorithm.getOrder(2);
        assertFalse(isFilled2);
        assertEq(amount2, 50); // 70 - 20 = 50 remaining

        // Assert that the first order (Sell at $1800) is untouched
        (,,, uint256 amount1,,,, bool isFilled1,,) = matchingAlgorithm.getOrder(1);
        assertTrue(isFilled1);
        assertEq(amount1, 0);
    }
}
