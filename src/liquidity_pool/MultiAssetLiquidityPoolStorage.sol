// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../governance/GovernanceToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract MultiAssetLiquidityPoolStorage is ReentrancyGuard, ERC20, ERC1155Holder, Ownable {
    enum TokenType {
        ERC20,
        ERC1155
    }

    struct PoolInfo {
        uint256 reserveA;
        uint256 reserveB;
        TokenType tokenAType;
        TokenType tokenBType;
    }

    struct LiquidityProvider {
        uint256 liquidityAmount;
        uint256 lastUpdateTime;
        uint256 rewardDebt;
    }

    mapping(bytes32 => PoolInfo) public pools;
    mapping(address => LiquidityProvider) public liquidityProviders;

    GovernanceToken public governanceToken;
    uint256 public rewardRate = 2e18;

    event RewardsClaimed(address indexed user, uint256 reward);
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);

    // Add the setRewardRate function to allow setting or updating the reward rate
    function setRewardRate(uint256 _rewardRate) external nonReentrant onlyOwner {
        rewardRate = _rewardRate;
    }

    function transferToken(
        address token,
        TokenType tokenType,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount
    ) internal nonReentrant {
        if (tokenType == TokenType.ERC20) {
            if (from == address(this)) {
                IERC20(token).transfer(to, amount);
            } else {
                IERC20(token).transferFrom(from, to, amount);
            }
            emit TokenTransferred(token, from, to, tokenId, amount, "ERC20");
        } else if (tokenType == TokenType.ERC1155) {
            IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
            emit TokenTransferred(token, from, to, tokenId, amount, "ERC1155");
        }
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    event TokenTransferred(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 amount,
        string tokenType
    );

    function getPoolId(address tokenA, address tokenB, uint256 tokenAId, uint256 tokenBId)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(tokenA, tokenB, tokenAId, tokenBId));
    }

    function updateReward(address user) internal {
        LiquidityProvider storage provider = liquidityProviders[user];

        if (provider.liquidityAmount > 0) {
            uint256 timeElapsed = 3600; // For simplicity
            uint256 reward = (provider.liquidityAmount * rewardRate * timeElapsed);
            provider.rewardDebt += reward;
        }

        provider.lastUpdateTime = block.timestamp;
    }
}
