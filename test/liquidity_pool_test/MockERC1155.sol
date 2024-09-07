// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155("https://example.com") {
        // Mint some ERC1155 tokens to the deployer
        _mint(msg.sender, 1, 1000, ""); // Mint 1,000 tokens of ID 1
    }
}
