// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title VulnerableVault
 * @dev VIOLATES CEI PATTERN: Interaction occurs BEFORE the Effect.
 * This code is used only for researching and testing the Attacker.sol exploit.
 */

contract VulnerableVault {
    using Address for address payable;

    mapping(address => uint256) private _balances;

    // Notice: No nonReentrant modifier and no State Machine (FSM)
    
    function deposit() external payable {
        _balances[msg.sender] += msg.value;
    }

    /**
     * @dev VULNERABLE WITHDRAW
     * This function is the target for the Attacker.sol contract.
     */

    function withdraw(uint256 amount) external {
        // 1. CHECK balance
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        // 2. INTERACTION (The Flaw: External call happens BEFORE the state update)
        // This triggers the Attacker's receive() function while the 
        // vault still thinks the user has their full balance.
        payable(msg.sender).sendValue(amount);

        // 3. EFFECT (The Flaw: This line is never reached during an attack)
        unchecked { // Stimulate the behavior of older, vulnerable contracts (like DAO)
            _balances[msg.sender] -= amount;
        }
    }

    function getBalance(address user) external view returns (uint256) {
        return _balances[user];
    }
}
