
## **MonadX**___________________________        ![MonadX](https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQSgnWRV7cmpYTtjJX1ordkFZGOWbO_6Zy8gg&s)
The on-chain version of dexter. Development is in progress with a few tests done already. Security auditing, gas optimisation, UX and adminstrative tooling todo 
### Test Results Summary

#### GovernanceTokenTest (GovernanceToken.t.sol)

-   **Number of Tests**: 4
-   **Test Details**:
    -   **testBurning**: Passed (Gas: 54,239)
    -   **testInitialMint**: Passed (Gas: 12,913)
    -   **testMinting**: Passed (Gas: 46,859)
    -   **testVotingPower**: Passed (Gas: 12,864)
-   **Result**: All 4 tests passed; finished in 2.77ms (654.35µs CPU time).

#### ImmediateOrCancelOrderTest (IocOrder.t.sol)

-   **Number of Tests**: 2
-   **Test Details**:
    -   **testIOCFullMatch**: Passed (Gas: 167,705)
    -   **testIOCPartialMatch**: Passed (Gas: 168,951)
-   **Result**: All 4 tests passed; finished in 16.67ms (2.41ms CPU time).

#### StopLimitOrderTest (StopLimitOrder.t.sol)

-   **Number of Tests**: 4
-   **Test Details**:
    -   **testStopLimitBuyOrder**: Passed (Gas: 337,146)
    -   **testStopLimitOrderNotTriggered**: Passed (Gas: 201,937)
    -   **testStopLimitSellOrder**: Passed (Gas: 336,479)
    -   **testTriggerMultipleStopLimitOrders**: Passed (Gas: 361,796)
-   **Result**: All 4 tests passed; finished in 3.95ms (2.12ms CPU time).

#### MarketOrderTest (MarketOrder.t.sol)

-   **Number of Tests**: 4
-   **Test Details**:
    -   **testMarketBuyOrder**: Passed (Gas: 426,594)
    -   **testMarketBuyOrderFailsNoSellOrders**: Passed (Gas: 11,359)
    -   **testMarketBuyOrderPartialMultiple**: Passed (Gas: 438,320)
    -   **testMarketSellOrder**: Passed (Gas: 500,331)
-   **Result**: All 4 tests passed; finished in 4.12ms (2.28ms CPU time).

#### LiquidityProviderTest (LiquidityProvider.t.sol)

-   **Number of Tests**: 2
-   **Test Details**:
    -   **testAddLiquidityAndAccrueRewards**: Passed (Gas: 294,455)
    -   **testClaimRewards**: Passed (Gas: 349,068)
-   **Result**: All 2 tests passed; finished in 4.17ms (1.36ms CPU time).

#### MatchingAlgorithmTest (MatchingAlgorithm.t.sol)

-   **Number of Tests**: 5
-   **Test Details**:
    -   **testCancelOrderWithLogs**: Passed (Gas: 179,595)
    -   **testMatchOrders**: Passed (Gas: 300,055)
    -   **testOrderShouldNotMatchIfCancelled**: Passed (Gas: 318,217)
    -   **testPlaceLimitBuyOrder**: Passed (Gas: 183,170)
    -   **testPlaceLimitSellOrder**: Passed (Gas: 163,378)
-   **Result**: All 5 tests passed; finished in 4.34ms (2.07ms CPU time).

#### MultiAssetLiquidityPoolTest (MultiAssetLiquidityPool.t.sol)

-   **Number of Tests**: 4
-   **Test Details**:
    -   **testAddLiquidity**: Passed (Gas: 298,093)  
        _Logs: Allowance after adding liquidity: 0_
    -   **testERC20Approval**: Passed (Gas: 39,400)
    -   **testRemoveLiquidity**: Passed (Gas: 381,262)  
        _Logs: Allowance after adding liquidity: 2000000000000000000000_  
        _Allowance after removing liquidity: 2000000000000000000000_
    -   **testSwapAForB**: Passed (Gas: 308,114)  
        _Logs: User1 initial balance: 500, current balance: 500_  
        _Swap failed due to insufficient liquidity_
-   **Result**: All 4 tests passed; finished in 4.36ms (2.52ms CPU time).

#### GovernorTest (Governor.t.sol)

-   **Number of Tests**: 3
-   **Test Details**:
    -   **testCreateProposal**: Passed (Gas: 118,700)
    -   **testExecuteProposal**: Passed (Gas: 309,192)  
        _Logs: Yes votes: 331662479030000000000, No votes: 244948974270000000000, Total votes: 576611453300000000000, Quorum: 7000000000000_
    -   **testVoting**: Passed (Gas: 270,034)
-   **Result**: All 3 tests passed; finished in 4.64ms (3.01ms CPU time).

### Overall Summary

-   **Total Test Suites**: 8
-   **Total Tests**: 28
-   **Passed**: 28
-   **Failed**: 0
-   **Skipped**: 0
-   **Total Execution Time**: 283.45ms (28.35ms CPU time)

All tests passed successfully with no failures or skips.
