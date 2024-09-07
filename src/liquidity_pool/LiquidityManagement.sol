// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiAssetLiquidityPoolStorage.sol";

abstract contract LiquidityManagement is ReentrancyGuard, MultiAssetLiquidityPoolStorage {
    // ! reentrancy permitted !
    // transfer token protected
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 tokenAId,
        uint256 tokenBId,
        uint256 amountA,
        uint256 amountB,
        TokenType tokenAType,
        TokenType tokenBType,
        uint256 minLiquidity
    ) external returns (uint256 liquidity) {
        bytes32 poolId = getPoolId(tokenA, tokenB, tokenAId, tokenBId);
        PoolInfo storage pool = pools[poolId];

        if (totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
            pool.reserveA = amountA;
            pool.reserveB = amountB;
            pool.tokenAType = tokenAType;
            pool.tokenBType = tokenBType;
        } else {
            uint256 amountBOptimal = (amountA * pool.reserveB) / pool.reserveA;
            require(amountB >= amountBOptimal, "Amount B too low");

            liquidity = (totalSupply() * amountA) / pool.reserveA;
        }

        require(liquidity >= minLiquidity, "Slippage: Insufficient liquidity minted");

        transferToken(tokenA, tokenAType, msg.sender, address(this), tokenAId, amountA);
        transferToken(tokenB, tokenBType, msg.sender, address(this), tokenBId, amountB);

        pool.reserveA += amountA;
        pool.reserveB += amountB;

        updateReward(msg.sender);
        _mint(msg.sender, liquidity);

        liquidityProviders[msg.sender].liquidityAmount += liquidity;
        liquidityProviders[msg.sender].lastUpdateTime = block.timestamp;

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    // ! reentrancy permitted !
    // transfer token protected
    function removeLiquidity(address tokenA, address tokenB, uint256 tokenAId, uint256 tokenBId, uint256 liquidity)
        external
        returns (uint256 amountA, uint256 amountB)
    {
        bytes32 poolId = getPoolId(tokenA, tokenB, tokenAId, tokenBId);
        PoolInfo storage pool = pools[poolId];

        require(liquidityProviders[msg.sender].liquidityAmount >= liquidity, "Not enough liquidity");

        updateReward(msg.sender);

        amountA = (liquidity * pool.reserveA) / totalSupply();
        amountB = (liquidity * pool.reserveB) / totalSupply();

        pool.reserveA -= amountA;
        pool.reserveB -= amountB;

        transferToken(tokenA, pool.tokenAType, address(this), msg.sender, tokenAId, amountA);
        transferToken(tokenB, pool.tokenBType, address(this), msg.sender, tokenBId, amountB);

        _burn(msg.sender, liquidity);

        liquidityProviders[msg.sender].liquidityAmount -= liquidity;
        liquidityProviders[msg.sender].lastUpdateTime = block.timestamp;

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }
}
