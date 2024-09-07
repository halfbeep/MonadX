// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./GovernanceToken.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Governor is ReentrancyGuard, Ownable {
    GovernanceToken public governanceToken;
    uint256 public proposalCount = 0;
    uint256 public votingDuration = 3 days;
    uint256 public quorum = 700 * 10 ** 10; // Minimum voting power needed for quorum

    constructor(address _governanceTokenAddress) Ownable(msg.sender) {
        governanceToken = GovernanceToken(_governanceTokenAddress);
    }

    struct Proposal {
        uint256 id;
        string description;
        uint256 startTime;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
        mapping(address => bool) voted;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 id, string description, uint256 startTime);
    event Voted(address voter, uint256 proposalId, bool vote, uint256 votingPower);
    event ProposalExecuted(uint256 id, bool passed);

    // Create a new proposal
    function createProposal(string memory _description) external nonReentrant {
        require(
            governanceToken.balanceOf(msg.sender, governanceToken.VOTING_TOKEN()) > 0,
            "Must have voting tokens to propose"
        );

        proposalCount++;
        Proposal storage newProposal = proposals[proposalCount];
        newProposal.id = proposalCount;
        newProposal.description = _description;
        newProposal.startTime = block.timestamp;

        emit ProposalCreated(proposalCount, _description, block.timestamp);
    }

    // Get details of a proposal (returns a tuple of values)
    function getProposal(uint256 _proposalId)
        external
        view
        returns (
            uint256 id,
            string memory description,
            uint256 startTime,
            uint256 yesVotes,
            uint256 noVotes,
            bool executed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.description,
            proposal.startTime,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.executed
        );
    }

    // Vote on a proposal (yes or no)
    function vote(uint256 _proposalId, bool _support) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.startTime, "Voting has not started yet");
        require(block.timestamp <= proposal.startTime + votingDuration, "Voting period has ended");
        require(!proposal.voted[msg.sender], "You have already voted");

        uint256 votingPower = quadraticVotingPower(msg.sender);
        require(votingPower > 0, "No voting power");

        if (_support) {
            proposal.yesVotes += votingPower;
        } else {
            proposal.noVotes += votingPower;
        }

        proposal.voted[msg.sender] = true;

        emit Voted(msg.sender, _proposalId, _support, votingPower);
    }

    // Execute a proposal after the voting period
    function executeProposal(uint256 _proposalId) external nonReentrant {
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp > proposal.startTime + votingDuration, "Voting period is not over");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.yesVotes + proposal.noVotes >= quorum, "Quorum not reached");

        bool passed = proposal.yesVotes > proposal.noVotes;
        proposal.executed = true;

        emit ProposalExecuted(_proposalId, passed);
    }

    // Calculate quadratic voting power
    function quadraticVotingPower(address voter) public view returns (uint256) {
        uint256 balance = governanceToken.balanceOf(voter, governanceToken.VOTING_TOKEN());
        return sqrt(balance) * 10 ** 10; // Scale up quadratic voting power
    }

    // Utility function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
