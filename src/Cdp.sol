// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// NOTE: Solmate doesn't check for token existence, this may cause bugs if you enable any collateral
import {SafeTransferLib} from "../lib/solmate/src/utils/SafeTransferLib.sol";
import {AggregatorV3Interface} from "../lib/chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "../lib/solmate/src/tokens/ERC20.sol";
import {eBTC} from "./eBTC.sol";

enum RepayWith {
    EBTC,
    COLLATERAL
}

interface ICallbackRecipient {

    function flashMintCallback(address initiator, uint256 amount, bytes memory data) external returns (RepayWith, uint256);
}

contract Cdp {
    using SafeTransferLib for ERC20;

    uint256 constant MAX_BPS = 10_000;
    uint256 constant LIQUIDATION_TRESHOLD = 10_000; // 100% in BPS
    uint256 constant RATIO_DECIMALS = 10 ** 8;

    eBTC immutable public EBTC;

    ERC20 immutable public COLLATERAL;

    uint256 totalDeposited;

    uint256 totalBorrowed;

    uint256 ratio = 3e17;

    uint256 constant LTV_PERCENTAGE = 8e17;

    address owner;

    AggregatorV3Interface internal priceFeed;

    constructor() {
        EBTC = new eBTC();
        // WETH
        COLLATERAL = ERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        // BTC/ETH Oracle
        priceFeed = AggregatorV3Interface(0xdeb288F737066589598e9214E782fa5A8eD689e8);
    }

    /**
     * Returns the latest ratio between BTC and ETH
     */
    function getLatestRatio() public view returns (int) {
        (
            /*uint80 roundID*/,
            int256 ethToBtcRatio,
            /*uint startedAt*/,
            uint256 updatedAt,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        // Make sure CL was updated recently
        uint16 threshold = 60 * 60 * 3; // Three hours
        require(updatedAt > block.timestamp - threshold, "Feed wasn't updated recently");
        return ethToBtcRatio;
    }

    function getRatio() public view returns (uint256) {
        int256 ethToBtcRatio = getLatestRatio();
        require(ethToBtcRatio > 0, "ETH to BTC ratio is negative");
        return 1e18 * RATIO_DECIMALS / (uint(ethToBtcRatio));
    }

    function flash(uint256 amount, ICallbackRecipient target, bytes memory data) external {
        // No checks as we allow minting after

        // Effetcs
        uint256 newTotalBorrowed = totalBorrowed + amount;

        totalBorrowed = newTotalBorrowed;

        // Interactions
        // Flash mint amount
        EBTC.mint(address(target), amount);


        // Callback
        (RepayWith collateralChoice, uint256 repayAmount) = target.flashMintCallback(msg.sender, amount, data);


        // Check solvency
        if(totalBorrowed > maxBorrow()) {
            if(collateralChoice == RepayWith.EBTC) {
                uint256 minRepay = totalBorrowed - maxBorrow();
                // They must repay
                // This is min repayment
                require(repayAmount >= minRepay);

                // TODO: This may be gameable must fuzz etc.. this is a toy project bruh
                totalBorrowed -= repayAmount;

                // Get the repayment
                // EBTC Cannot reenter because we know impl, DO NOT ADD HOOKS OR YOU WILL GET REKT
                EBTC.burn(address(target), repayAmount);
            } else {
                // They repay with collateral

                // NOTE: WARN
                // This can reenter for sure, DO NOT USE IN PROD
                deposit(repayAmount);

                assert(isSolvent());
            }
        }
    }

    event Debug(string name, uint256 amount);


    // Deposit
    function deposit(uint256 amount) public {
        // Increase deposited
        totalDeposited += amount;

        if (owner == address(0)) {
            owner = msg.sender;
        }

        // Check delta + transfer
        uint256 prevBal = COLLATERAL.balanceOf(address(this));
        emit Debug("prevBal", prevBal);
        COLLATERAL.safeTransferFrom(msg.sender, address(this), amount);
        uint256 afterBal = COLLATERAL.balanceOf(address(this));

        // Make sure we got the amount we expected
        require(afterBal - prevBal == amount, "No feeOnTransfer");   
    }

    // Borrow
    function borrow(uint256 amount) external {
        // Checks
        uint256 newTotalBorrowed = totalBorrowed + amount;
        
        // Check if borrow is solvent
        uint256 maxBorrowCached = maxBorrow();

        require(newTotalBorrowed <= maxBorrowCached, "Over debt limit");

        // Effect
        totalBorrowed = newTotalBorrowed;

        // Interaction
        EBTC.mint(msg.sender, amount);
    }
    /// Calculate maximal borrow amount using formula:
    /// Deposited ETH * (ETH / BTC  ratio) = Value
    /// Value * LTV = Max Borrow
    function maxBorrow() public view returns (uint256) {
        return totalDeposited * getRatio() * LTV_PERCENTAGE / RATIO_DECIMALS;
    }

    function isSolvent() public view returns (bool) {
        return totalBorrowed <= maxBorrow();
    }

    // Liquidate
    function liquidate() external {
        require(!isSolvent(), "Must be insolvent");

        uint256 excessDebt = totalBorrowed - maxBorrow();


        // Give the contract to liquidator
        owner = msg.sender;


        // Burn the token
        EBTC.burn(msg.sender, excessDebt);
    }

}