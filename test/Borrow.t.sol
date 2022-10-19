// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {Cdp} from "../src/Cdp.sol";
import {Dai} from "../src/Cdp.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";


contract SampleContractTest is Test {
    using SafeTransferLib for ERC20;


    ERC20 public constant BADGER = ERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);

    address user;

    Cdp cdpContract;

    function getSomeToken() internal {
        vm.prank(0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e);
        BADGER.safeTransfer(address(this), 123e18);
        assert(BADGER.balanceOf(address(this)) == 123e18);
    }

    function setUp() public {
        cdpContract = new Cdp(BADGER);
        user = address(this);
    }

    function testbasicBorrow(uint32 amount) public {
        /*
        * Simple fuzz test covering basic borrowing against
        * properly deposited collateral
        * TODO: Mock Oracle for Cdp.ratio once it's added
        */
        getSomeToken();

        // Deposit collateral first
        BADGER.safeApprove(address(cdpContract), 1337);
        cdpContract.deposit(1337);

        cdpContract.borrow(amount);
        assert(cdpContract.DAI().balanceOf(user) == amount);
    }

    function testFailBorrowOverLimitNoCollateral() public {
        // Case when borrowing against no  collateral at all
        uint256 borrowedAmt = 1000;
        cdpContract.borrow(borrowedAmt);
        // Make sure user didn't borrow anything
        assert(cdpContract.DAI().balanceOf(user) == 0);
    }
}
