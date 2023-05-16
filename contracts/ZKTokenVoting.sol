// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import {IVotesPerVoter} from "./IVotesPerVoter.sol";

/// @dev Acts in place of a token that Openzeppelin's GovernorVotes expects.
/// We use it here as an allowlist of eligible voters.
/// A list of voters is passed in during construction, and never changed.
/// Consider this "soulbound" voting rights for the time being.
/// TODO: Change this later.
contract ZKTokenVoting is IVotes, IVotesPerVoter {
    mapping(address voter => bool canVote) private s_voters;
    uint256 private immutable s_totalNumberOfVoters;

    constructor(address[] memory voters) {
        for (uint256 i = 0; i < voters.length; i++) {
            s_voters[voters[i]] = true;
        }
        s_totalNumberOfVoters = voters.length;
    }

    function votesPerVoter() external pure override(IVotesPerVoter) returns (uint256) {
        return 1;
    }

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view override(IVotes) returns (uint256) {
        return (s_voters[account] ? 1 : 0);
    }

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256) external view override(IVotes) returns (uint256) {
        return (s_voters[account] ? 1 : 0);
    }

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256) external view override(IVotes) returns (uint256) {
        return s_totalNumberOfVoters;
    }

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address) external pure override(IVotes) returns (address) {
        revert();
    }

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address) external pure override(IVotes) {
        revert();
    }

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) external pure override(IVotes) {
        revert();
    }
}
