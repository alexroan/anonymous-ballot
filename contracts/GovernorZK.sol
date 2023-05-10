// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IGovernor, Governor, IERC165} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCompatibilityBravo} from
    "@openzeppelin/contracts/governance/compatibility/GovernorCompatibilityBravo.sol";
import {IVotes, GovernorVotes} from "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import {GovernorVotesQuorumFraction} from
    "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import {
    TimelockController,
    GovernorTimelockControl
} from "@openzeppelin/contracts/governance/extensions/GovernorTimelockControl.sol";
import {ZKTree, IHasher, IVerifier} from "zk-merkle-tree/contracts/ZKTree.sol";

contract GovernorZK is
    Governor,
    GovernorCompatibilityBravo,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    ZKTree
{
    error WrongState(ProposalState actual, ProposalState expected);
    error AlreadyCommitted(uint256 proposalId, address voter);
    error NotEligible(address voter);
    error InvalidCommitment(uint256 commitment);

    mapping(uint256 proposalId => mapping(address voter => bool commited)) public s_hasCommitted;

    constructor(
        IVotes _token,
        TimelockController _timelock,
        uint32 zkTreeLevels,
        IHasher zkHasher,
        IVerifier zkVerifier
    )
        Governor("GovernorZK")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(50)
        GovernorTimelockControl(_timelock)
        ZKTree(zkTreeLevels, zkHasher, zkVerifier)
    {}

    /// @dev Commit function
    /// should be called by the voter during the Pending phase,
    /// should reach out to _getVotes to get the voter's voting power,
    /// should store commitment in the merkle tree
    function registerCommitment(uint256 proposalId, uint256 commitment) external {
        // check the state is pending
        ProposalState proposalState = state(proposalId);
        if (proposalState != ProposalState.Pending) revert WrongState(proposalState, ProposalState.Pending);
        // check if the msg.sender has already committed for this vote
        if (s_hasCommitted[proposalId][msg.sender]) revert AlreadyCommitted(proposalId, msg.sender);
        // check that the msg.sender is eligible to commit for this vote
        uint256 weight = getVotes(msg.sender, proposalSnapshot(proposalId));
        if (weight == 0) revert NotEligible(msg.sender);
        // check that the commitment is valid
        if (commitment == 0) revert InvalidCommitment(commitment);

        // commit
        _commit(bytes32(commitment));
        s_hasCommitted[proposalId][msg.sender] = true;
    }

    // TODO Override and revert existing castVote functions
    // TODO Implement new castVote functions with ZK proofs

    /// BLOILERPLATE BELOW ///

    function votingDelay() public pure override returns (uint256) {
        return 6575; // 1 day
    }

    function votingPeriod() public pure override returns (uint256) {
        return 46027; // 1 week
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }

    // The functions below are overrides required by Solidity.

    function state(uint256 proposalId)
        public
        view
        override(Governor, IGovernor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override(Governor, GovernorCompatibilityBravo, IGovernor) returns (uint256) {
        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor() internal view override(Governor, GovernorTimelockControl) returns (address) {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, IERC165, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
