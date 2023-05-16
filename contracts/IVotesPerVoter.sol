// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface IVotesPerVoter {
    /// @dev Return the number of votes per eligible voter
    function votesPerVoter() external view returns (uint256);
}
