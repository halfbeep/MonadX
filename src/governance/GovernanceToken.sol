// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract GovernanceToken is ReentrancyGuard, ERC1155, Ownable {
    uint256 public constant VOTING_TOKEN = 1;
    uint256 public constant REWARD_TOKEN = 2;

    mapping(uint256 => uint256) private _totalSupply;
    address public liquidityPoolContract;

    // Declare Mint and Burn events
    event Mint(address indexed account, uint256 id, uint256 amount);
    event Burn(address indexed account, uint256 id, uint256 amount);

    constructor(string memory uri) ERC1155(uri) Ownable(msg.sender) {
        // Mint initial tokens to msg.sender
        _mint(msg.sender, VOTING_TOKEN, 1000 * 10 ** 18, "");
        _mint(msg.sender, REWARD_TOKEN, 500 * 10 ** 18, "");

        // Update the total supply
        _totalSupply[VOTING_TOKEN] = 1000 * 10 ** 18;
        _totalSupply[REWARD_TOKEN] = 500 * 10 ** 18;
    }

    // Mint function to allow the liquidity pool contract to mint reward tokens
    function mint(address account, uint256 id, uint256 amount) external nonReentrant {
        require(msg.sender == owner() || msg.sender == liquidityPoolContract, "Not authorized to mint");
        _mint(account, id, amount, "");
        _totalSupply[id] += amount;
        emit Mint(account, id, amount);
    }

    // Set the liquidity pool contract to allow it to mint reward tokens
    function setLiquidityPoolContract(address _liquidityPoolContract) external nonReentrant onlyOwner {
        liquidityPoolContract = _liquidityPoolContract;
    }

    // Burn function for token holders
    function burn(address account, uint256 id, uint256 amount) external nonReentrant {
        require(account == msg.sender, "You can only burn your own tokens");
        _burn(account, id, amount);
        _totalSupply[id] -= amount; // Update total supply

        emit Burn(account, id, amount); // Emit burn event
    }

    // Function to view voting power
    function votingPower(address account) external view returns (uint256) {
        return balanceOf(account, VOTING_TOKEN);
    }

    // Total supply of a specific token type
    function totalSupply(uint256 id) external view returns (uint256) {
        return _totalSupply[id];
    }
}
