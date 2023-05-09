// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "./IAllowList.sol";

contract AddressList is IAllowList {
    mapping(address => bool) public isAllowed;

    constructor(address[] memory allowed) {
        for (uint256 i = 0; i < allowed.length; i++) {
            isAllowed[allowed[i]] = true;
        }
    }
}