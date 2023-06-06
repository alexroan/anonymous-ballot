// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {GovernorCompatibilityZK, Governor} from "../../contracts/GovernorCompatibilityZK.sol";

contract GovernorCompatibilityZKMock is GovernorCompatibilityZK {
    constructor() Governor("Mock") {}

    function _getVotes(address account, uint256 blockNumber) internal view override returns (uint256) {}
    function proposalEta(uint256 proposalId) public view override returns (uint256) {}
    function queue(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        public
        override
        returns (uint256)
    {}
    function quorum(uint256 blockNumber) public view override returns (uint256) {}
    function timelock() public view override returns (address) {}
    function votingDelay() public view override returns (uint256) {}
    function votingPeriod() public view override returns (uint256) {}

    /// @dev ZK friendly countVote
    function countVoteInternal(uint256 proposalId, bytes32 nullifier, uint8 support, uint256 weight) public {
        _countVote(proposalId, nullifier, support, weight);
    }
}
