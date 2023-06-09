// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IGovernor, Governor, IERC165} from "./Governor.sol";
import {GovernorCompatibilityZK} from "./GovernorCompatibilityZK.sol";
import {IGovernorZK} from "./IGovernorZK.sol";
import {IVotes, GovernorVotes} from "./GovernorVotes.sol";
import {IVotesPerVoter} from "./IVotesPerVoter.sol";
import {GovernorVotesQuorumFraction} from "./GovernorVotesQuorumFraction.sol";
import {TimelockController, GovernorTimelockControl} from "./GovernorTimelockControl.sol";
import {ZKTree, IHasher, IVerifier} from "zk-merkle-tree/contracts/ZKTree.sol";

contract GovernorZK is
    IGovernorZK,
    Governor,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    GovernorCompatibilityZK,
    ZKTree
{
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
    function registerCommitment(uint256 proposalId, uint256 commitment) external override(IGovernorZK) {
        // check the state is pending
        ProposalState proposalState = state(proposalId);
        if (proposalState != ProposalState.Pending) revert WrongState(proposalState, ProposalState.Pending);
        // check if the msg.sender has already committed for this vote
        if (hasCommitted(proposalId, msg.sender)) revert AlreadyCommitted(proposalId, msg.sender);
        // check that the msg.sender is eligible to commit for this vote
        uint256 weight = getVotes(msg.sender, proposalSnapshot(proposalId));
        if (weight == 0) revert NotEligible(msg.sender);
        // check that the commitment is valid
        if (commitment == 0) revert InvalidCommitment(commitment);

        // commit
        _commit(bytes32(commitment));
        _registerCommitment(proposalId, msg.sender);
    }

    /// @dev castVote with ZK proofs
    function castVote(
        uint256 proposalId,
        uint8 support,
        uint256 nullifier,
        uint256 root,
        uint256[2] calldata proof_a,
        uint256[2][2] calldata proof_b,
        uint256[2] calldata proof_c
    ) external override(IGovernorZK) {
        _castVote(proposalId, support, "", nullifier, root, proof_a, proof_b, proof_c);
    }

    /// @dev castVote with ZK proofs
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string memory reason,
        uint256 nullifier,
        uint256 root,
        uint256[2] calldata proof_a,
        uint256[2][2] calldata proof_b,
        uint256[2] calldata proof_c
    ) public override(IGovernorZK) {
        _castVote(proposalId, support, reason, nullifier, root, proof_a, proof_b, proof_c);
    }

    function _castVote(
        uint256 proposalId,
        uint8 support,
        string memory reason,
        uint256 nullifier,
        uint256 root,
        uint256[2] calldata proof_a,
        uint256[2][2] calldata proof_b,
        uint256[2] calldata proof_c
    ) internal {
        // Check that the state is active
        ProposalState proposalState = state(proposalId);
        if (proposalState != ProposalState.Active) revert WrongState(proposalState, ProposalState.Active);

        // nullify the commitment
        bytes32 bNullifier = bytes32(nullifier);
        _nullify(bNullifier, bytes32(root), proof_a, proof_b, proof_c);

        // Currently this returns 1, as we assume that if your commitment is part of the merkle tree, then your voting power is 1.
        // Potentially have tranches of merkle trees (1, 10, 100, etc) to allow for more voting power.
        // TODO: Think more about this in future versions.
        uint256 votes = IVotesPerVoter(address(token)).votesPerVoter();

        _countVote(proposalId, bNullifier, support, votes);

        emit VoteCast(bNullifier, proposalId, support, votes, reason);
    }

    /// BLOILERPLATE BELOW ///

    function votingDelay() public pure override returns (uint256) {
        return 46027; // 1 week
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
    ) public override(Governor, IGovernor, GovernorCompatibilityZK) returns (uint256) {
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
