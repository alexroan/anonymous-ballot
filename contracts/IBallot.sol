// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface IBallot {
    error NotEligible(address registrant);
    error AlreadyCommitted(address registrant);
    error InvalidCommitment(uint256 commitment);
    error CommitmentDeadlinePassed(uint256 commitmentDeadline);
    error CommitmentDeadlineNotPassed(uint256 commitmentDeadline);
    error InvalidOption(uint256 option);

    function registerCommitment(uint256 commitment) external;

    function vote(
        uint256 option,
        uint256 nullifier,
        uint256 root,
        uint256[2] calldata proof_a,
        uint256[2][2] calldata proof_b,
        uint256[2] calldata proof_c
    ) external;
}
