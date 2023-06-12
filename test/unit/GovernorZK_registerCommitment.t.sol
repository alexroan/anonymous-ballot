// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "../BaseTest.t.sol";
import {Verifier} from "../../contracts/generated/Verifier.sol";
import {ZKTokenVoting} from "../../contracts/ZKTokenVoting.sol";
import {IGovernorZK, GovernorZK} from "../../contracts/GovernorZK.sol";
import {IGovernor} from "../../contracts/IGovernor.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {MerkleTreeWithHistory, IHasher} from "zk-merkle-tree/contracts/MerkleTreeWithHistory.sol";
import {IVerifier} from "zk-merkle-tree/contracts/ZKTree.sol";

contract GovernorZK_registerCommitmentTest is BaseTest {
    IHasher internal constant HASHER = IHasher(mimcAddress);

    GovernorZK internal s_governor;
    uint256 internal s_proposalId;

    function setUp() public virtual override {
        BaseTest.setUp();
        Verifier verifier = new Verifier();
        address[] memory voters = new address[](5);
        voters[0] = USER_0;
        voters[1] = USER_1;
        voters[2] = USER_2;
        voters[3] = USER_3;
        voters[4] = USER_4;
        ZKTokenVoting voting = new ZKTokenVoting(voters);

        address[] memory proposers = new address[](1);
        proposers[0] = USER_0;
        TimelockController timelock = new TimelockController(0, proposers, proposers, USER_0);
        s_governor = new GovernorZK(voting, timelock, 20, HASHER, IVerifier(address(verifier)));

        address[] memory targets = new address[](1);
        targets[0] = USER_0;
        uint256[] memory values = new uint256[](1);
        values[0] = 0;
        bytes[] memory calldatas = new bytes[](1);
        calldatas[0] = "0x";
        changePrank(USER_0);
        s_proposalId = IGovernor(s_governor).propose(targets, values, calldatas, "Test Proposal");
    }

    function test_registerCommitment_invalidCommitmentFails() public {
        vm.expectRevert(abi.encodeWithSelector(IGovernorZK.InvalidCommitment.selector, 0));
        s_governor.registerCommitment(s_proposalId, 0);
    }

    function test_registerCommitment_wrongStateFails() public {
        vm.warp(s_governor.proposalDeadline(s_proposalId) + 1);
        vm.roll(s_governor.proposalSnapshot(s_proposalId) + 1);
        vm.expectRevert(
            abi.encodeWithSelector(
                IGovernorZK.WrongState.selector, IGovernor.ProposalState.Active, IGovernor.ProposalState.Pending
            )
        );
        s_governor.registerCommitment(s_proposalId, 1);
    }

    function test_registerCommitment_alreadyCommittedFails() public {
        s_governor.registerCommitment(s_proposalId, 1);
        vm.expectRevert(abi.encodeWithSelector(IGovernorZK.AlreadyCommitted.selector, s_proposalId, USER_0));
        s_governor.registerCommitment(s_proposalId, 1);
    }

    function test_registerCommitment_notEligibleFails() public {
        changePrank(USER_5);
        vm.expectRevert(abi.encodeWithSelector(IGovernorZK.NotEligible.selector, USER_5));
        s_governor.registerCommitment(s_proposalId, 1);
    }

    function test_registerCommitment_commitmentAlreadySubmittedFails() public {
        s_governor.registerCommitment(s_proposalId, 1);
        changePrank(USER_1);
        vm.expectRevert("The commitment has been submitted");
        s_governor.registerCommitment(s_proposalId, 1);
    }

    event Commit(bytes32 indexed commitment, uint32 leafIndex, uint256 timestamp);

    function test_registerCommitment_success(uint256) public {
        (uint256 nullifier, uint256 secret, bytes32 commitment, bytes32 nullifierHash) = generateCommitment();
        vm.expectEmit(true, true, true, true);
        emit Commit(commitment, 0, block.timestamp);
        s_governor.registerCommitment(s_proposalId, uint256(commitment));
        assertTrue(s_governor.commitments(commitment));
    }

    function generateCommitment()
        private
        returns (uint256 nullifier, uint256 secret, bytes32 commitment, bytes32 nullifierHash)
    {
        nullifier = _random() % s_governor.FIELD_SIZE();
        secret = _random() % s_governor.FIELD_SIZE();
        commitment = s_governor.hashLeftRight(nullifier, secret);
        nullifierHash = s_governor.hashLeftRight(nullifier, 0);
    }
}
