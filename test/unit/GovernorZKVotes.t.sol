// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {BaseTest} from "../BaseTest.t.sol";
import {GovernorZKVotes} from "../../contracts/GovernorZKVotes.sol";

contract GovernorZKVotesTest is BaseTest {
    GovernorZKVotes internal s_votes;

    function setUp() public virtual override {
        BaseTest.setUp();
        address[] memory addresses = new address[](5);
        addresses[0] = USER_0;
        addresses[1] = USER_1;
        addresses[2] = USER_2;
        addresses[3] = USER_3;
        addresses[4] = USER_4;
        s_votes = new GovernorZKVotes(addresses);
    }

    function testGetVotes() public {
        assertEq(s_votes.getVotes(USER_0), 1);
        assertEq(s_votes.getVotes(USER_5), 0);
    }

    function testGetPastVotes() public {
        assertEq(s_votes.getPastVotes(USER_0, 0), 1);
        assertEq(s_votes.getPastVotes(USER_5, 0), 0);
    }

    function testGetPastTotalSupply() public {
        assertEq(s_votes.getPastTotalSupply(0), 5);
    }

    function testDelegates() public {
        vm.expectRevert();
        s_votes.delegates(USER_0);
    }

    function testDelegate() public {
        vm.expectRevert();
        s_votes.delegate(USER_0);
    }

    function testDelegateBySig() public {
        vm.expectRevert();
        s_votes.delegateBySig(USER_0, 0, 0, 0, 0, 0);
    }
}
