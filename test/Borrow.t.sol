// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {Cdp} from "../src/Cdp.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";


contract BorrowTest is Test {
    using SafeTransferLib for ERC20;

    ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address user;
    uint256 collateral_amount;

    Cdp cdpContract;

    function getSomeToken() internal {
        vm.prank(0xD0A7A8B98957b9CD3cFB9c0425AbE44551158e9e);
        WETH.safeTransfer(address(this), 123e18);
        assert(WETH.balanceOf(address(this)) == 123e18);
    }

    function setUp() public {
        cdpContract = new Cdp();
        user = address(this);
        collateral_amount = 123e18; // 123 WETH deposited
    }

    function testbasicBorrow(uint32 amount) public {
        /*
        * Simple fuzz test covering basic borrowing against
        * properly deposited collateral
        * TODO: Mock Oracle for Cdp.ratio once it's added
        */
        getSomeToken();

        // Deposit collateral first
        WETH.safeApprove(address(cdpContract), collateral_amount);
        cdpContract.deposit(collateral_amount);
        cdpContract.borrow(amount);
        assert(cdpContract.EBTC().balanceOf(user) == amount);
    }

    function testFailBorrowOverLimitNoCollateral() public {
        // Case when borrowing against no collateral at all
        uint256 borrowedAmt = 1000;
        cdpContract.borrow(borrowedAmt);
        // Make sure user didn't borrow anything
        assert(cdpContract.EBTC().balanceOf(user) == 0);
    }
}
