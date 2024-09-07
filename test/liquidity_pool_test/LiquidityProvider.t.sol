// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol";
import "../../src/liquidity_pool/MultiAssetLiquidityPool.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../../src/governance/GovernanceToken.sol";
import "./MockERC20.sol";
import "./MockERC1155.sol";

contract LiquidityProviderTest is Test, ERC1155Holder {
    MultiAssetLiquidityPool public liquidityPool;
    GovernanceToken public governanceToken;
    MockERC20 public erc20Token;
    MockERC1155 public erc1155Token;

    address public user1 = address(0x123);
    address public user2 = address(0x456);

    uint256 public initialRewardRate = 1e18; // Rewards per second per liquidity token

    function setUp() public {
        // Deploy GovernanceToken contract
        governanceToken = new GovernanceToken("https://example.com");

        // Deploy MultiAssetLiquidityPool contract, passing the GovernanceToken's address
        liquidityPool = new MultiAssetLiquidityPool(address(governanceToken));

        // Authorize liquidity pool to mint governance tokens
        governanceToken.setLiquidityPoolContract(address(liquidityPool));

        // Set reward rate (adjust this value based on your requirements)
        liquidityPool.setRewardRate(100000000e18); // 1 token per second per liquidity unit

        // Deploy mock tokens
        erc20Token = new MockERC20();
        erc1155Token = new MockERC1155();

        // Provide some initial governance tokens for rewards (minting to the liquidity pool contract)
        governanceToken.mint(address(this), governanceToken.REWARD_TOKEN(), 10000000 * 1e18); // 100k reward tokens

        // Mint some tokens for user1 for testing
        erc20Token.transfer(user1, 1000 * 10 ** 18); // Transfer 1000 tokens to user1
        erc1155Token.safeTransferFrom(address(this), user1, 1, 100, ""); // Transfer 100 ERC1155 tokens to user1
    }

    function testClaimRewards() public {
        // Simulate user1 adding liquidity
        vm.startPrank(user1);

        // Approve the liquidity pool to spend the tokens
        erc20Token.approve(address(liquidityPool), 1000 * 10 ** 18);
        erc1155Token.setApprovalForAll(address(liquidityPool), true);

        uint256 amountA = 1000 * 1e18;
        uint256 amountB = 100;
        liquidityPool.addLiquidity(
            address(erc20Token),
            address(erc1155Token),
            0,
            1,
            amountA,
            amountB,
            MultiAssetLiquidityPoolStorage.TokenType.ERC20,
            MultiAssetLiquidityPoolStorage.TokenType.ERC1155,
            1
        );
        vm.stopPrank();

        // Fast-forward time by 1 hour to simulate reward accrual
        vm.warp(block.timestamp + 1 hours);

        // Claim the rewards for user1
        vm.startPrank(user1);
        liquidityPool.claimRewards();
        vm.stopPrank();

        // Check that user1 received the correct amount of governance tokens
        uint256 expectedRewards = (316227766016 * initialRewardRate * 3600 * 100000000);
        uint256 user1Balance = governanceToken.balanceOf(user1, governanceToken.REWARD_TOKEN());
        assertEq(user1Balance, expectedRewards, "User1 should have received the correct amount of governance tokens");
    }

    function testAddLiquidityAndAccrueRewards() public {
        // Simulate user adding liquidity
        vm.startPrank(user1);
        erc20Token.approve(address(liquidityPool), 1000 * 1e18);
        erc1155Token.setApprovalForAll(address(liquidityPool), true);
        liquidityPool.addLiquidity(
            address(erc20Token),
            address(erc1155Token),
            0,
            1,
            1000 * 1e18,
            100,
            MultiAssetLiquidityPoolStorage.TokenType.ERC20,
            MultiAssetLiquidityPoolStorage.TokenType.ERC1155,
            1
        );
        vm.stopPrank();

        // Simulate the passage of 1 day to accrue rewards
        vm.warp(block.timestamp + 12 hours); // Fast-forward ,5 day for significant rewards

        // Verify that the rewards are calculated correctly
        uint256 expectedRewards = (316227766016 * 100000000 * 3600 * 1e18); // Example calculation
        uint256 rewardDebt = liquidityPool.viewReward(user1);
        assertEq(rewardDebt, expectedRewards, "Rewards should match expected amount");
    }
}
