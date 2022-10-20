// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";

import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {EbtcTest} from "./EbtcTest.sol";


contract SampleContractTest is EbtcTest {
    using SafeTransferLib for ERC20;

    function testBasicSetupWorks() public {
        getSomeToken();
        assert(cdpContract.COLLATERAL() == WETH);
    }

    function testBasicDeposit() public {
        // Test is scoped so you need to re-do setup each test
        getSomeToken();
        WETH.safeApprove(address(cdpContract), 1337);
        cdpContract.deposit(1337);
    }

    function testGetMaxBorrow() public {
        getSomeToken();
        int256 expRatio = 14802961150000000000;
        uint256 validThreshold = block.timestamp - 60 * 60 * 1;
        // Mock CL call to return expRatio as BTC/ETH ratio
        mockRateGetterCL(expRatio, validThreshold);
        uint256 collateral = 1e18;  // ETH
        WETH.safeApprove(address(cdpContract), collateral);
        cdpContract.deposit(collateral);
        // Calculate expected max borrow value
        uint256 expectedMaxBorrow = (
            collateral * EBTC.decimals() / uint(cdpContract.getLatestRatio()) * cdpContract.LTV_PERCENTAGE()
        );
        uint256 maxBorrow = cdpContract.maxBorrow();
        assertEq(maxBorrow, expectedMaxBorrow);
        vm.clearMockedCalls();
    }

    function testgetLatestRatio() public {
        // Simple test case to check that Oracle doesn't return zero values
        int256 expRatio = 14802961150000000000;
        uint256 validThreshold = block.timestamp - 60 * 60 * 1; // 1 Hour, CL was updated recently
        // Make sure getLatestRatio() fails when CL wasn't updated recently
        mockRateGetterCL(expRatio, validThreshold);
        int ratio = cdpContract.getLatestRatio();
        assertEq(ratio, expRatio);
        vm.clearMockedCalls();
    }

    function testFailgetLatestRatioCLNotUpdated() public {
        // Test for case when CL wasn't updated for 10 hours, so getLatestRatio must fail
        int256 expRatio = 14802961150000000000;
        uint256 thresholdToFail = block.timestamp - 60 * 60 * 25; // 25 Hours
        // Make sure getLatestRatio() fails when CL wasn't updated recently
        mockRateGetterCL(expRatio, thresholdToFail);
        cdpContract.getLatestRatio();
        vm.clearMockedCalls();
    }
    function testFailgetLatestRatioCLReturnedNegativeNumber() public {
        // Test for case when CL for some reason returned negative value
        int256 expRatio = -14802961150000000000;
        uint256 validThreshold = block.timestamp - 60 * 60 * 1; // 1 Hour, CL was updated recently
        // Make sure getLatestRatio() fails when CL wasn't updated recently
        mockRateGetterCL(expRatio, validThreshold);
        cdpContract.getLatestRatio();
        vm.clearMockedCalls();
    }
}
