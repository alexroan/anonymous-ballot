// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "../BaseTest.t.sol";
import {MerkleTreeWithHistory, IHasher} from "zk-merkle-tree/contracts/ZKTree.sol";

contract MiMCTest is BaseTest {
    function setUp() public override {
        BaseTest.setUp();
    }

    function testLeftRight() public {
        MerkleTreeWithHistory tree = new MerkleTreeWithHistory(20, IHasher(mimcAddress));

        uint256 left = 3601779045281873076346102090660016220952686121357428626285619814305527995;
        uint256 right = 287175522742315729107319759796840092441740521122434097311061860151925499169;
        bytes32 commitment = tree.hashLeftRight(left, right);
        bytes32 correctAnswer = 0x0446e305d9f46132f1670559855cfb7eef967d0bf7cfb1ed42fc16a46f8479df;
        assertEq(commitment, correctAnswer);
    }
}
