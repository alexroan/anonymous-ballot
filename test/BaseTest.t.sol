// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

contract BaseTest is Test {
    address internal constant USER_0 = address(0x01);
    address internal constant USER_1 = address(0x02);
    address internal constant USER_2 = address(0x03);
    address internal constant USER_3 = address(0x04);
    address internal constant USER_4 = address(0x05);
    address internal constant USER_5 = address(0x06);
    address internal constant USER_6 = address(0x07);
    address internal constant USER_7 = address(0x08);
    address internal constant USER_8 = address(0x09);
    address internal constant USER_9 = address(0x10);

    function setUp() public virtual {
        vm.startPrank(USER_0);
    }
}
