// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {BaseTest} from "../BaseTest.t.sol";
import {IBallot, AnonymousBallot} from "../../contracts/AnonymousBallot.sol";
import {IAllowList} from "../../contracts/allowlists/IAllowList.sol";
import {IHasher, IVerifier} from "zk-merkle-tree/contracts/ZKTree.sol";

contract AnonymousBallotTest is BaseTest {
    AnonymousBallot internal s_ballot;

    IHasher internal s_mockHasher;
    IVerifier internal s_mockVerifier;
    IAllowList internal s_mockAllowList;

    uint256 internal s_commitmentDuration = 1000;

    function setUp() public override {
        BaseTest.setUp();
        s_ballot = new AnonymousBallot(
            20, // change this later when tree size is dynamic
            s_mockHasher,
            s_mockVerifier,
            s_mockAllowList,
            s_commitmentDuration
        );
    }
}

contract AnonymousBallotTest_registerCommitment is AnonymousBallotTest {
    function test_nonEligibleSender() public {
        vm.mockCall(
            address(s_mockAllowList), abi.encodeWithSelector(IAllowList.isAllowed.selector, USER_0), abi.encode(false)
        );

        vm.expectRevert(abi.encodeWithSelector(IBallot.NotEligible.selector, USER_0));
        s_ballot.registerCommitment(12345);
    }
    // TODO

    function test_senderAlreadyCommitted() public {}
    // TODO
    function test_invalidCommitment() public {}
    // TODO
    function test_commitmentDeadlinePassed() public {}
    // TODO
    function test_success() public {}
}

contract AnonymousBallotTest_vote is AnonymousBallotTest {
// TODO
}
