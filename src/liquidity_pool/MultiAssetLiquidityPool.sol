// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityManagement.sol";
import "./RewardManagement.sol";
import "./MultiAssetLiquidityPoolStorage.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract MultiAssetLiquidityPool is ReentrancyGuard, LiquidityManagement, RewardManagement {
    event Swap(
        address indexed user,
        address indexed tokenA,
        address indexed tokenB,
        uint256 tokenAId,
        uint256 tokenBId,
        uint256 amountAIn,
        uint256 amountBOut,
        uint256 reserveAAfter,
        uint256 reserveBAfter
    );

    constructor(address _governanceTokenAddress) ERC20("Liquidity Pool Token", "LPT") Ownable(msg.sender) {
        governanceToken = GovernanceToken(_governanceTokenAddress);
    }

    // Swap ERC-20/1155 tokenA for tokenB
    function swapAForB(
        address tokenA,
        address tokenB,
        uint256 tokenAId,
        uint256 tokenBId,
        uint256 amountAIn,
        uint256 minAmountBOut,
        TokenType tokenAType,
        TokenType tokenBType
    ) external nonReentrant {
        bytes32 poolId = getPoolId(tokenA, tokenB, tokenAId, tokenBId);
        PoolInfo storage pool = pools[poolId];

        uint256 amountBOut = getAmountOut(amountAIn, pool.reserveA, pool.reserveB);
        require(amountBOut >= minAmountBOut, "Insufficient output amount");

        transferToken(tokenA, tokenAType, msg.sender, address(this), tokenAId, amountAIn);
        transferToken(tokenB, tokenBType, address(this), msg.sender, tokenBId, amountBOut);

        uint256 reserveAAfter = pool.reserveA + amountAIn;
        uint256 reserveBAfter = pool.reserveB - amountBOut;

        // Emit the swap event
        emit Swap(msg.sender, tokenA, tokenB, tokenAId, tokenBId, amountAIn, amountBOut, reserveAAfter, reserveBAfter);

        pool.reserveA = reserveAAfter;
        pool.reserveB = reserveBAfter;
    }

    // Get the output amount based on the constant product formula
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        uint256 amountInWithFee = amountIn * 997; // 0.3% fee
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }
}
