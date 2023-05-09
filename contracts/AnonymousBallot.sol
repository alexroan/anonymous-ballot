// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {ZKTree, IHasher, IVerifier} from "../node_modules/zk-merkle-tree/contracts/ZKTree.sol";
import {IAllowList} from "./allowlists/IAllowList.sol";
import {IBallot} from "./IBallot.sol";

/// @dev An anonymous ballot with a single round of voting.
contract AnonymousBallot is IBallot, ZKTree {
    // COMMITMENT / REGISTRATION PHASE
    IAllowList public immutable i_allowList;
    uint256 public immutable i_commitmentDeadline;
    mapping(address voter => bool commited) public s_hasCommitted;

    // Vote options
    uint256 public constant OPTION_A = 99;
    uint256 public constant OPTION_B = 98;

    // VOTE PHASE
    mapping(uint256 option => uint256 votes) public s_voteTally;

    constructor(uint32 levels, IHasher hasher, IVerifier verifier, IAllowList allowList, uint256 commitmentDuration)
        ZKTree(levels, hasher, verifier)
    {
        i_allowList = allowList;
        i_commitmentDeadline = block.timestamp + commitmentDuration;
    }

    function registerCommitment(uint256 commitment) external override {
        if (!i_allowList.isAllowed(msg.sender)) revert NotEligible(msg.sender);
        if (s_hasCommitted[msg.sender]) revert AlreadyCommitted(msg.sender);
        if (commitment == 0) revert InvalidCommitment(commitment);
        if (block.timestamp > i_commitmentDeadline) revert CommitmentDeadlinePassed(i_commitmentDeadline);

        _commit(bytes32(commitment));
        s_hasCommitted[msg.sender] = true;
    }

    function vote(
        uint256 option,
        uint256 nullifier,
        uint256 root,
        uint256[2] calldata proof_a,
        uint256[2][2] calldata proof_b,
        uint256[2] calldata proof_c
    ) external override {
        if (block.timestamp <= i_commitmentDeadline) revert CommitmentDeadlineNotPassed(i_commitmentDeadline);
        if (option != OPTION_A && option != OPTION_B) revert InvalidOption(option);

        _nullify(bytes32(nullifier), bytes32(root), proof_a, proof_b, proof_c);

        s_voteTally[option]++;
    }
}
