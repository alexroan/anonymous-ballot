// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {BaseTest} from "../BaseTest.t.sol";
import {GovernorCompatibilityZKMock} from "../mocks/GovernorCompatibilityZKMock.sol";

contract GovernorCompatibilityZKTest is BaseTest {
    GovernorCompatibilityZKMock internal s_compat;

    function setUp() public virtual override {
        BaseTest.setUp();
        s_compat = new GovernorCompatibilityZKMock();
    }

    function test_COUNTING_MODE() public {
        assertEq(s_compat.COUNTING_MODE(), "support=bravo&quorum=bravo");
    }

    // propose functions

    function test_propose() public {
        (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas,
            string memory description
        ) = generateTestProposalValues();
        signatures = new string[](1);
        signatures[0] = "";

        uint256 proposalId = s_compat.propose(targets, values, calldatas, description);

        assertProposalValues(proposalId);
        assertProposalActions(proposalId, targets, values, signatures, calldatas);
    }

    function test_proposeWithSignatures() public {
        (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas,
            string memory description
        ) = generateTestProposalValues();
        uint256 proposalId = s_compat.propose(targets, values, signatures, calldatas, description);

        assertProposalValues(proposalId);
        assertProposalActions(proposalId, targets, values, signatures, calldatas);
    }

    // Event copied from GovernorCompatibilityZKMock.t.sol
    event QueueCalled(address[] targets, uint256[] values, bytes[] calldatas, bytes32 descriptionHash);

    function test_queue() public {
        (address[] memory targets, uint256[] memory values,, bytes[] memory calldatas, string memory description) =
            generateTestProposalValues();
        bytes32 descriptionHash = keccak256(bytes(description));
        uint256 proposalId = s_compat.propose(targets, values, calldatas, description);

        vm.expectEmit(true, true, true, true);
        emit QueueCalled(targets, values, calldatas, descriptionHash);
        s_compat.queue(proposalId);
    }

    function test_execute() public {
        // TODO
    }

    function test_cancel() public {
        // TODO
    }

    function test__countVoteZK_For() public {
        (address[] memory targets, uint256[] memory values,, bytes[] memory calldatas, string memory description) =
            generateTestProposalValues();
        uint256 proposalId = s_compat.propose(targets, values, calldatas, description);

        (,,,,, uint256 forVotesBefore,,,,) = s_compat.proposals(proposalId);

        bytes32 nullifier = bytes32(0);
        uint8 support = 1;
        uint256 weight = 1;
        s_compat.countVoteInternal(proposalId, nullifier, support, weight);

        (,,,,, uint256 forVotesAfter,,,,) = s_compat.proposals(proposalId);
        assertGt(forVotesAfter, forVotesBefore);
    }

    function test__countVoteZK_Against() public {
        (address[] memory targets, uint256[] memory values,, bytes[] memory calldatas, string memory description) =
            generateTestProposalValues();
        uint256 proposalId = s_compat.propose(targets, values, calldatas, description);

        (,,,,,, uint256 againstVotesBefore,,,) = s_compat.proposals(proposalId);

        bytes32 nullifier = bytes32(0);
        uint8 support = 0;
        uint256 weight = 1;
        s_compat.countVoteInternal(proposalId, nullifier, support, weight);

        (,,,,,, uint256 againstVotesAfter,,,) = s_compat.proposals(proposalId);
        assertGt(againstVotesAfter, againstVotesBefore);
    }

    function test__countVoteZK_Abstain() public {
        (address[] memory targets, uint256[] memory values,, bytes[] memory calldatas, string memory description) =
            generateTestProposalValues();
        uint256 proposalId = s_compat.propose(targets, values, calldatas, description);

        (,,,,,,, uint256 abstainVotesBefore,,) = s_compat.proposals(proposalId);

        bytes32 nullifier = bytes32(0);
        uint8 support = 2;
        uint256 weight = 1;
        s_compat.countVoteInternal(proposalId, nullifier, support, weight);

        (,,,,,,, uint256 abstainVotesAfter,,) = s_compat.proposals(proposalId);
        assertGt(abstainVotesAfter, abstainVotesBefore);
    }

    // Test Helpers

    function assertProposalValues(uint256 proposalId) internal {
        (
            uint256 id,
            address proposer,
            uint256 eta,
            uint256 startBlock,
            uint256 endBlock,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 abstainVotes,
            bool canceled,
            bool executed
        ) = s_compat.proposals(proposalId);

        assertEq(id, proposalId);
        assertEq(proposer, USER_0);
        assertEq(eta, 0);
        assertEq(startBlock, block.number);
        assertEq(endBlock, block.number + s_compat.votingPeriod());
        assertEq(forVotes, 0);
        assertEq(againstVotes, 0);
        assertEq(abstainVotes, 0);
        assertEq(canceled, false);
        assertEq(executed, false);
    }

    function assertProposalActions(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) public {
        (
            address[] memory targetsStored,
            uint256[] memory valuesStored,
            string[] memory signaturesStored,
            bytes[] memory calldatasStored
        ) = s_compat.getActions(proposalId);

        assertEq(targetsStored[0], targets[0]);
        assertEq(valuesStored[0], values[0]);
        assertEq(signaturesStored[0], signatures[0]);
        assertEq(calldatasStored[0], calldatas[0]);
    }

    function generateTestProposalValues()
        public
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas,
            string memory description
        )
    {
        targets = new address[](1);
        targets[0] = USER_0;
        values = new uint256[](1);
        values[0] = 0;
        signatures = new string[](1);
        signatures[0] = "test()";
        calldatas = new bytes[](1);
        calldatas[0] = abi.encodeWithSignature("test()");
        description = "test";
    }
}
