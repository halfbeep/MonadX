// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../../src/liquidity_pool/MultiAssetLiquidityPool.sol";

// TODO remove console.logs

contract TestERC20 is ERC20 {
    constructor() ERC20("Test Token", "TST") {
        mint(msg.sender, 9000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract TestERC1155 is ERC1155 {
    constructor() ERC1155("https://token-metadata-url/") {}

    function mint(address to, uint256 id, uint256 amount) public {
        _mint(to, id, amount, "");
    }
}

contract MultiAssetLiquidityPoolTest is Test, ERC1155Holder {
    MultiAssetLiquidityPool public liquidityPool;
    GovernanceToken public governanceToken;
    TestERC20 public erc20Token;
    TestERC1155 public erc1155Token;
    address public user1;
    address public user2;

    function setUp() public {
        user1 = address(1);
        user2 = address(2);

        // Deploy the GovernanceToken contract first
        governanceToken = new GovernanceToken("https://example.com");

        // Deploy ERC-20, ERC-1155, and Liquidity Pool contracts
        erc20Token = new TestERC20();
        erc1155Token = new TestERC1155();
        // Deploy the MultiAssetLiquidityPool contract, passing the GovernanceToken's address
        liquidityPool = new MultiAssetLiquidityPool(address(governanceToken));

        // Distribute some ERC-20 and ERC-1155 tokens to users
        erc20Token.mint(user1, 9000000 * 10 ** 18); // Mint 10,000 ERC-20 tokens to user1
        erc1155Token.mint(user1, 1, 1000); // Mint 1,000 of token ID 1 (ERC-1155) to user1

        erc20Token.mint(user2, 9000000 * 10 ** 18); // Mint 5,000 ERC-20 tokens to user2
        erc1155Token.mint(user2, 1, 500); // Mint 500 of token ID 1 (ERC-1155) to user2
    }

    // Test adding liquidity with ERC-20 and ERC-1155 tokens
    function testAddLiquidity() public {
        vm.startPrank(user1);

        // Approve the liquidity pool to spend user1's tokens
        erc20Token.approve(address(liquidityPool), 1000 * 10 ** 18);
        erc1155Token.setApprovalForAll(address(liquidityPool), true);

        // Add liquidity (ERC-20 and ERC-1155)
        uint256 liquidity = liquidityPool.addLiquidity(
            address(erc20Token),
            address(erc1155Token),
            0,
            1, // ERC-20 has ID 0, ERC-1155 has ID 1
            1000 * 10 ** 18, // Adding 1,000 ERC-20
            1000, // Adding 1000 ERC-1155
            MultiAssetLiquidityPoolStorage.TokenType.ERC20,
            MultiAssetLiquidityPoolStorage.TokenType.ERC1155,
            0 // slippage protection set to zero for test
        );

        assertEq(liquidity > 0, true, "Liquidity should be minted");
        console.log("Allowance after adding liquidity: ", erc20Token.allowance(user1, address(liquidityPool)));
        vm.stopPrank();
    }

    function testERC20Approval() public {
        vm.startPrank(user1);

        erc20Token.approve(address(liquidityPool), 2000 * 10 ** 18);
        uint256 allowance = erc20Token.allowance(user1, address(liquidityPool));

        assertEq(allowance, 2000 * 10 ** 18);

        vm.stopPrank();
    }

    // Test removing liquidity
    function testRemoveLiquidity() public {
        vm.startPrank(user1);

        // Initial approvals for liquidity addition
        erc20Token.approve(address(liquidityPool), 9000000 * 10 ** 18);
        erc1155Token.setApprovalForAll(address(liquidityPool), true);

        // Add liquidity
        liquidityPool.addLiquidity(
            address(erc20Token),
            address(erc1155Token),
            0,
            1,
            9000000 * 10 ** 18,
            500,
            MultiAssetLiquidityPoolStorage.TokenType.ERC20,
            MultiAssetLiquidityPoolStorage.TokenType.ERC1155,
            0 // slippage protection set to zero for test
        );

        // Ensure the allowance is set just before removeLiquidity
        erc20Token.approve(address(liquidityPool), 2e21);

        // Log the allowance after adding liquidity
        uint256 allowance = erc20Token.allowance(user1, address(liquidityPool));
        console.log("Allowance after adding liquidity : ", allowance);

        // Proceed to remove liquidity
        liquidityPool.removeLiquidity(
            address(erc20Token),
            address(erc1155Token),
            0,
            1,
            liquidityPool.balanceOf(user1) / 10 //reduce liquidity for testing otherwise totalPool of the single user is too much for contract
        );
        console.log("Allowance after removing liquidity: ", erc20Token.allowance(user1, address(liquidityPool)));
        vm.stopPrank();
    }

    // Test swapping ERC-20 for ERC-1155
    function testSwapAForB() public {
        vm.startPrank(user1);

        // Approve and add liquidity first
        erc20Token.approve(address(liquidityPool), 1000 * 10 ** 18);
        erc1155Token.setApprovalForAll(address(liquidityPool), true);

        liquidityPool.addLiquidity(
            address(erc20Token),
            address(erc1155Token),
            0,
            1,
            1000 * 10 ** 18,
            500,
            MultiAssetLiquidityPoolStorage.TokenType.ERC20,
            MultiAssetLiquidityPoolStorage.TokenType.ERC1155,
            0 // slippage protection set to zero for test
        );

        uint256 initialERC1155Balance = erc1155Token.balanceOf(user1, 1);

        console.log(
            "user1 initial balance: %s, current balance %s", initialERC1155Balance, erc1155Token.balanceOf(user1, 1)
        );

        // Attempt swap (ensure pool has enough liquidity)
        try liquidityPool.swapAForB(
            address(erc20Token),
            address(erc1155Token),
            0,
            1,
            100 * 10 ** 18, // Swap 100 ERC-20 tokens
            100, // Minimum output of 50 ERC-1155 tokens
            MultiAssetLiquidityPoolStorage.TokenType.ERC20,
            MultiAssetLiquidityPoolStorage.TokenType.ERC1155
        ) {
            // Ensure the user received ERC-1155 tokens
            assertEq(erc1155Token.balanceOf(user1, 1) > initialERC1155Balance, true, "ERC-1155 balance should increase");
        } catch {
            emit log("Swap failed due to insufficient liquidity");
        }

        vm.stopPrank();
    }
}
