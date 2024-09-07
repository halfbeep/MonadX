// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiAssetLiquidityPoolStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract RewardManagement is ReentrancyGuard, MultiAssetLiquidityPoolStorage {
    function claimRewards() external nonReentrant {
        updateReward(msg.sender);

        uint256 reward = liquidityProviders[msg.sender].rewardDebt;
        require(reward > 0, "No rewards to claim");

        liquidityProviders[msg.sender].rewardDebt = 0;

        governanceToken.mint(msg.sender, governanceToken.REWARD_TOKEN(), reward);

        emit RewardsClaimed(msg.sender, reward);
    }

    function viewReward(address user) external view returns (uint256) {
        LiquidityProvider storage provider = liquidityProviders[user];
        if (provider.liquidityAmount == 0) {
            return 0;
        }

        uint256 timeElapsed = 3600; // For simplicity
        uint256 pendingReward = (provider.liquidityAmount * rewardRate * timeElapsed);
        return provider.rewardDebt + pendingReward;
    }
}
