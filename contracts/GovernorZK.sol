// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IGovernor, Governor, IERC165} from "@openzeppelin/contracts/governance/Governor.sol";
import {GovernorCompatibilityZK} from "./compatibility/GovernorCompatibilityZK.sol";
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
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl,
    GovernorCompatibilityZK,
    ZKTree
{
    error WrongState(ProposalState actual, ProposalState expected);
    error AlreadyCommitted(uint256 proposalId, address voter);
    error NotEligible(address voter);
    error InvalidCommitment(uint256 commitment);
    error NotImplemented();

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

    /// @dev this overrides _castVote. All castVote functions in inherited contracts
    /// that call it therefore revert. We use our own caseVote function that uses ZK proofs.
    function _castVote(uint256, address, uint8, string memory, bytes memory) internal pure override returns (uint256) {
        revert NotImplemented();
    }

    // TODO Implement new castVote functions with ZK proofs
    function castVote(
        uint256 proposalId,
        uint8 support,
        uint256 nullifier,
        uint256 root,
        uint256[2] calldata proof_a,
        uint256[2][2] calldata proof_b,
        uint256[2] calldata proof_c
    ) external {
        // Check that the state is active
        ProposalState proposalState = state(proposalId);
        if (proposalState != ProposalState.Active) revert WrongState(proposalState, ProposalState.Active);

        // nullify the commitment
        _nullify(bytes32(nullifier), bytes32(root), proof_a, proof_b, proof_c);

        _countVote(
            proposalId,
            bytes32(nullifier),
            support,
            1 // hard coded for now... Perhaps have the circuit prove that the weight is correct?
                // TODO Pass it in as a param when casting a vote? Something to think about later
        );

        // TODO event
        // emit VoteCast(nullifier, proposalId, support, 1);
    }

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
