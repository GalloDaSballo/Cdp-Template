// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";

import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {AggregatorV3Interface} from "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    
    // Become this guy
    address user;

    Cdp cdpContract;

    function getSomeToken() internal {
        vm.prank(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WETH.safeTransfer(address(this), 123e18);
        assert(WETH.balanceOf(address(this)) == 123e18);
    }

    function setUp() public {
        cdpContract = new Cdp();
        user = address(this);
    }

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

    function testgetLatestRatio() public view {
        // Simple test case to check that Oracle doesn't return zero values
        int ratio = cdpContract.getLatestRatio();
        assert(ratio != 0);
    }

    function testFailgetLatestRatioCLNotUpdated() public {
        // Test for case when CL wasn't updated for 10 hours, so getLatestRatio must fail
        int256 expRatio = 14802961150000000000;
        uint32 thresholdToFail = 60 * 60 * 25; // 25 Hours
        // Make sure getLatestRatio() fails when CL wasn't updated recently
        vm.mockCall(
            address(0xdeb288F737066589598e9214E782fa5A8eD689e8),  // CL address
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            // CL mock data
            abi.encode(73786976294838207540, expRatio, 1666261667, thresholdToFail, 73786976294838207540)
        );
        cdpContract.getLatestRatio();
        vm.clearMockedCalls();
    }
    function testFailgetLatestRatioCLReturnedNegativeNumber() public {
        // Test for case when CL for some reason returned negative value
        int256 expRatio = -14802961150000000000;
        uint16 validThreshold = 60 * 60 * 1; // 1 Hour, CL was updated recently
        // Make sure getLatestRatio() fails when CL wasn't updated recently
        vm.mockCall(
            address(0xdeb288F737066589598e9214E782fa5A8eD689e8),  // CL address
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            // CL mock data
            abi.encode(73786976294838207540, expRatio, 1666261667, validThreshold, 73786976294838207540)
        );
        cdpContract.getLatestRatio();
        vm.clearMockedCalls();
    }
}
