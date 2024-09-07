// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol";
import "../../src/governance/GovernanceToken.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract GovernanceTokenTest is Test, IERC1155Receiver {
    GovernanceToken token;
    address owner;
    address user;

    function setUp() public {
        owner = address(this); // The test contract acts as the owner
        user = address(2); // Define a simple EOA for testing

        // Deploy the GovernanceToken contract
        token = new GovernanceToken("https://token-metadata-url/");
    }

    // Implement the ERC1155Receiver functions to handle incoming tokens
    function onERC1155Received(
        address, /*operator*/
        address, /*from*/
        uint256, /*id*/
        uint256, /*value*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /*operator*/
        address, /*from*/
        uint256[] calldata, /*id*/
        uint256[] calldata, /*value*/
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }

    function testInitialMint() public view {
        // Check initial balance of the owner (voting tokens)
        assertEq(token.balanceOf(owner, 1), 1000 * 10 ** 18);
    }

    function testMinting() public {
        // Mint additional tokens for the user
        token.mint(user, 1, 100);

        // Verify the user's balance increased
        assertEq(token.balanceOf(user, 1), 100);
    }

    function testBurning() public {
        // Mint and then burn tokens for the user
        token.mint(user, 1, 100);

        // Simulate user interaction
        vm.prank(user);
        token.burn(user, 1, 50);

        // Verify the user's balance decreased
        assertEq(token.balanceOf(user, 1), 50);
    }

    function testVotingPower() public view {
        // Check the voting power of the owner
        assertEq(token.votingPower(owner), 1000 * 10 ** 18);
    }
}
