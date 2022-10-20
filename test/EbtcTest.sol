// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {eBTC} from "../src/eBTC.sol";
import {Cdp} from "../src/Cdp.sol";
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {AggregatorV3Interface} from "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract EbtcTest is Test {
    using SafeTransferLib for ERC20;
    ERC20 public constant WETH = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address user;
    eBTC EBTC;
    Cdp cdpContract;

    function setUp() public virtual {
        cdpContract = new Cdp();
        user = address(this);
        EBTC = new eBTC();
    }

    function getSomeToken() internal {
        vm.prank(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        WETH.safeTransfer(address(this), 500e18);  // Get 500 ETH
        assert(WETH.balanceOf(address(this)) == 500e18);
    }

    function mockRateGetterCL(int256 rate, uint256 updatedAt) internal {
        // Don't forget to do vm.clearMockedCalls(); at the end of each test using this function
        vm.mockCall(
            address(0xdeb288F737066589598e9214E782fa5A8eD689e8),  // CL address
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            // CL mock data
            abi.encode(73786976294838207540, rate, 1666261667, updatedAt, 73786976294838207540)
        );
    }
}
