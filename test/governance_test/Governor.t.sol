// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@forge-std/Test.sol";
import "../../src/governance/Governor.sol";
import "../../src/governance/GovernanceToken.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@forge-std/console.sol";

contract GovernorTest is Test, IERC1155Receiver {
    Governor governor;
    GovernanceToken token;
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(this); // The test contract is the owner
        user1 = address(1);
        user2 = address(2);

        // Deploy GovernanceToken and Governance contracts
        token = new GovernanceToken("https://token-metadata-url/");
        governor = new Governor(address(token));

        // Mint voting tokens for testing
        token.mint(owner, 1, 1000 * 10 ** 18);
        token.mint(user1, 1, 500 * 10 ** 18);
        token.mint(user2, 1, 200 * 10 ** 18);
    }

    // Implement the IERC1155Receiver functions to handle incoming tokens
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

    function testCreateProposal() public {
        governor.createProposal("Proposal 1");

        // Access individual fields of the proposal using the getter function
        (, string memory description,,,,) = governor.getProposal(1);
        assertEq(description, "Proposal 1");
    }

    function testVoting() public {
        governor.createProposal("Proposal 1");

        // Vote yes with quadratic power
        vm.prank(user1);
        governor.vote(1, true);

        // Vote no with quadratic power
        vm.prank(user2);
        governor.vote(1, false);

        // Access individual fields using the getter function
        (,,, uint256 yesVotes, uint256 noVotes,) = governor.getProposal(1);

        assertEq(yesVotes, governor.quadraticVotingPower(user1));
        assertEq(noVotes, governor.quadraticVotingPower(user2));
    }

    function testExecuteProposal() public {
        governor.createProposal("Proposal 1");

        // Increase voting power to meet quorum
        token.mint(user1, 1, 600 * 10 ** 18); // Increase user1's voting power
        token.mint(user2, 1, 400 * 10 ** 18); // Increase user2's voting power

        vm.prank(user1);
        governor.vote(1, true);

        vm.prank(user2);
        governor.vote(1, false);

        // Check the voting power before execution
        (
            ,
            ,
            ,
            //uint256 id,
            //string memory description,
            //uint256 startTime,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed
        ) = governor.getProposal(1);
        console.log("Yes votes: %s", yesVotes);
        console.log("No votes: %s", noVotes);
        console.log("Total votes: %s", yesVotes + noVotes);
        console.log("Quorum: %s", governor.quorum());

        // Fast-forward time to after voting duration
        vm.warp(block.timestamp + 3 days + 1);
        governor.executeProposal(1);

        // Verify the proposal was executed
        (,,,,, executed) = governor.getProposal(1);
        assertEq(executed, true);
    }
}
