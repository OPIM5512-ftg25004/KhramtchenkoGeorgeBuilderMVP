// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SecureVault
 * @dev Implements CEI pattern and FSM for reentrancy protection.
 */
contract SecureVault is Ownable {
    using Address for address payable;

    // --- State Variables ---
    mapping(address => uint256) private _balances;
    bool private _locked; // Custom Reentrancy Guard state
    
    enum VaultState { Active, Paused, Emergency }
    VaultState public currentState;

    // --- Events ---
    event FundsDeposited(address indexed user, uint256 amount);
    event FundsWithdrawn(address indexed user, uint256 amount, uint256 remainingBalance);
    event StateChanged(VaultState newState);

    // --- Modifiers ---
    
    // Custom Reentrancy Guard logic
    modifier nonReentrant() {
        require(!_locked, "ReentrancyGuard: reentrant call");
        _locked = true;
        _;
        _locked = false;
    }

    // FSM State Check
    modifier whenActive() {
        require(currentState == VaultState.Active, "Vault: Not active");
        _;
    }

    constructor() Ownable(msg.sender) {
        currentState = VaultState.Active;
    }

    // --- Core Logic ---

    /**
     * @dev Simple deposit function to fund the user ledger.
     */
    function deposit() external payable whenActive {
        require(msg.value > 0, "Deposit must be > 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposited(msg.sender, msg.value);
    }

    /**
     * @dev The Security Core: Implements strict CEI pattern.
     */
    function withdraw(uint256 amount) external nonReentrant whenActive {
        // 1. CHECK: Validate balance and FSM state
        require(amount > 0, "Amount must be > 0");
        require(amount <= _balances[msg.sender], "Insufficient balance");

        // 2. EFFECT: Update state BEFORE external interaction
        _balances[msg.sender] -= amount;

        // 3. INTERACTION: External call last
        // Using OpenZeppelin's sendValue for security (reverts on failure)
        payable(msg.sender).sendValue(amount);

        emit FundsWithdrawn(msg.sender, amount, _balances[msg.sender]);
    }

    // --- Administrative Functions ---
    function setState(VaultState _newState) external onlyOwner {
        currentState = _newState;
        emit StateChanged(_newState);
    }

    function getBalance(address user) external view returns (uint256) {
        return _balances[user];
    }
}
