// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";


import {Cdp} from "../src/Cdp.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";

// Useful links
// How to steal tokens for forknet: 
// https://github.com/foundry-rs/forge-std/blob/2a2ce3692b8c1523b29de3ec9d961ee9fbbc43a6/src/Test.sol#L118-L150
// All the basics
// https://github.com/dabit3/foundry-cheatsheet
// Foundry manual
// https://book.getfoundry.sh/cheatcodes/


contract SampleContractTest is Test {

    ERC20 public constant BADGER = ERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    
    // Become this guy
    address user = address(1);

    Cdp cdpContract;

    function setUp() public {
        cdpContract = new Cdp(BADGER);

        vm.prank(user);

        // Get a bunch of collateral
        deal(address(BADGER), user, 123e18);
    }

    function testFunc1() public {
        cdpContract.deposit(1337);
    }
}
