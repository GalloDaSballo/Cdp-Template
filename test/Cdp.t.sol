// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";


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
    using SafeTransferLib for ERC20;


    ERC20 public constant BADGER = ERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    
    // Become this guy
    address user;

    Cdp cdpContract;

    function getSomeToken() internal {
        // become whale
        vm.prank(0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e);
        BADGER.safeTransfer(address(this), 123e18);
        assert(BADGER.balanceOf(address(this)) == 123e18);
    }

    function setUp() public {
        cdpContract = new Cdp(BADGER);
        user = address(this);
    }

    function testBasicSetupWorks() public {
        getSomeToken();
        assert(cdpContract.COLLATERAL() == BADGER);
    }

    function testBasicDeposit() public {
        // Test is scoped so you need to re-do setup each test
        getSomeToken();

        BADGER.safeApprove(address(cdpContract), 1337);
        cdpContract.deposit(1337);
    }

    function testgetLatestRatio() public view {
        // Simple test case to check that Oracle doesn't return zero values
        int ratio = cdpContract.getLatestRatio();
        assert(ratio != 0);
    }
}
