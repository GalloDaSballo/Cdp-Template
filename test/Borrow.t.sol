// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {Cdp} from "../src/Cdp.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {EbtcTest} from "./EbtcTest.sol";


contract BorrowTest is EbtcTest {
    using SafeTransferLib for ERC20;

    function testbasicBorrow(uint64 borrowedAmount) public {
        /*
        * Simple fuzz test covering basic borrowing against
        * properly deposited collateral
        */
        uint256 collateral_amount = 123e18; // 123 WETH to be deposited
        getSomeToken();
        int256 expRatio = 14802961150000000000;
        uint256 validThreshold = block.timestamp - 60 * 60 * 1;
        // Mock CL call to return expRatio as BTC/ETH ratio
        mockRateGetterCL(expRatio, validThreshold);
        // Deposit collateral first
        WETH.safeApprove(address(cdpContract), collateral_amount);
        cdpContract.deposit(collateral_amount);
        cdpContract.borrow(borrowedAmount);
        assert(cdpContract.EBTC().balanceOf(user) == borrowedAmount);
        vm.clearMockedCalls();
    }

    function testFailBorrowOverLimitNoCollateral() public {
        // Case when borrowing against no collateral at all
        uint256 borrowedAmt = 1000;
        cdpContract.borrow(borrowedAmt);
        // Make sure user didn't borrow anything
        assert(cdpContract.EBTC().balanceOf(user) == 0);
    }
}
