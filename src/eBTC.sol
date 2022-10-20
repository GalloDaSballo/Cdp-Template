// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract eBTC {
    address immutable OWNER;

    mapping(address => uint256) balances;

    constructor() {
        OWNER = msg.sender;
    }

    function mint(address recipient, uint256 amount) external {
        balances[recipient] += amount;
    }

    function balanceOf(address recipient) external view returns (uint256) {
        return balances[recipient];
    }

    function burn(address recipient, uint256 amount) external {
        balances[recipient] -= amount;
    }
}
