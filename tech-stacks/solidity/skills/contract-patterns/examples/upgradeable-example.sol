// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title MyUpgradeableContract
 * @dev Comprehensive UUPS upgradeable contract example with common features:
 * - UUPS Proxy Pattern: Upgrade logic in implementation contract
 * - Ownable: Access control for administrative functions
 * - Pausable: Emergency stop mechanism
 * - ReentrancyGuard: Protection against reentrancy attacks
 *
 * IMPORTANT NOTES:
 * 1. Use initializer instead of constructor
 * 2. Disable initializers in constructor
 * 3. Never remove _authorizeUpgrade function
 * 4. Be careful with storage layout changes
 * 5. Test upgrades thoroughly
 *
 * Deployment Process:
 * 1. Deploy implementation contract
 * 2. Deploy proxy pointing to implementation
 * 3. Call initialize() through proxy
 * 4. Interact with proxy address (not implementation)
 *
 * Upgrade Process:
 * 1. Deploy new implementation
 * 2. Call upgradeTo(newImplementation) on proxy
 * 3. Proxy now delegates to new implementation
 * 4. Storage is preserved
 */
contract MyUpgradeableContract is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev Version of the implementation
    uint256 public version;

    /// @dev Example storage variable
    uint256 public value;

    /// @dev Example mapping
    mapping(address => uint256) public userBalances;

    /// @dev Emitted when value is updated
    event ValueUpdated(uint256 oldValue, uint256 newValue);

    /// @dev Emitted when balance is updated
    event BalanceUpdated(address indexed user, uint256 oldBalance, uint256 newBalance);

    /**
     * @dev Constructor that disables initializers
     * This prevents the implementation contract from being initialized
     *
     * CRITICAL: Always include this in upgradeable contracts
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializer function (replaces constructor)
     * Called once when proxy is deployed
     *
     * @param initialOwner Address of the contract owner
     *
     * Requirements:
     * - Can only be called once (initializer modifier)
     */
    function initialize(address initialOwner) public initializer {
        // Initialize parent contracts
        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        // Initialize this contract's state
        version = 1;
        value = 0;
    }

    /**
     * @dev Reinitializer for upgrades that need state changes
     * Use this when upgrading to a new version that needs initialization
     *
     * @param newValue New value to set
     *
     * Requirements:
     * - Can only be called during upgrade to version 2
     */
    function initializeV2(uint256 newValue) public reinitializer(2) {
        version = 2;
        value = newValue;
    }

    /**
     * @dev Updates the value
     * @param newValue New value to set
     *
     * Requirements:
     * - Only owner can update
     * - Contract must not be paused
     */
    function setValue(uint256 newValue) public onlyOwner whenNotPaused {
        uint256 oldValue = value;
        value = newValue;
        emit ValueUpdated(oldValue, newValue);
    }

    /**
     * @dev Deposits funds for a user
     *
     * Requirements:
     * - Contract must not be paused
     * - Must send ETH with transaction
     */
    function deposit() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Must send ETH");

        uint256 oldBalance = userBalances[msg.sender];
        userBalances[msg.sender] += msg.value;

        emit BalanceUpdated(msg.sender, oldBalance, userBalances[msg.sender]);
    }

    /**
     * @dev Withdraws funds for a user
     * @param amount Amount to withdraw
     *
     * Requirements:
     * - Contract must not be paused
     * - User must have sufficient balance
     */
    function withdraw(uint256 amount) public whenNotPaused nonReentrant {
        require(userBalances[msg.sender] >= amount, "Insufficient balance");

        uint256 oldBalance = userBalances[msg.sender];
        userBalances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        emit BalanceUpdated(msg.sender, oldBalance, userBalances[msg.sender]);
    }

    /**
     * @dev Pauses all operations
     *
     * Requirements:
     * - Only owner can pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all operations
     *
     * Requirements:
     * - Only owner can unpause
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Returns the current implementation version
     */
    function getVersion() public view returns (uint256) {
        return version;
    }

    /**
     * @dev Authorization function for upgrades
     * This function is called by upgradeTo/upgradeToAndCall
     *
     * CRITICAL: Never remove this function!
     * Removing it would make the contract non-upgradeable
     *
     * @param newImplementation Address of new implementation
     *
     * Requirements:
     * - Only owner can authorize upgrades
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

/**
 * @title MyUpgradeableContractV2
 * @dev Example of an upgraded version with new functionality
 *
 * STORAGE LAYOUT RULES:
 * 1. Never remove existing state variables
 * 2. Never change the type of existing state variables
 * 3. Never change the order of state variables
 * 4. Only add new state variables at the end
 * 5. Use storage gaps for upgradeable contracts in production
 */
contract MyUpgradeableContractV2 is
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @dev KEEP: Existing state variables (DO NOT MODIFY)
    uint256 public version;
    uint256 public value;
    mapping(address => uint256) public userBalances;

    /// @dev NEW: Add new state variables at the end
    uint256 public multiplier;
    mapping(address => bool) public isWhitelisted;

    /// @dev NEW: Events for new functionality
    event MultiplierUpdated(uint256 newMultiplier);
    event UserWhitelisted(address indexed user);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Reinitializer for V2 upgrade
     *
     * Requirements:
     * - Called during upgrade to V2
     */
    function initializeV2() public reinitializer(2) {
        version = 2;
        multiplier = 2;
    }

    /**
     * @dev NEW: Sets the multiplier
     */
    function setMultiplier(uint256 newMultiplier) public onlyOwner {
        multiplier = newMultiplier;
        emit MultiplierUpdated(newMultiplier);
    }

    /**
     * @dev NEW: Whitelists a user
     */
    function whitelist(address user) public onlyOwner {
        isWhitelisted[user] = true;
        emit UserWhitelisted(user);
    }

    /**
     * @dev MODIFIED: Enhanced setValue with multiplier
     */
    function setValue(uint256 newValue) public onlyOwner whenNotPaused {
        value = newValue * multiplier;
        emit ValueUpdated(value, newValue);
    }

    /**
     * @dev Keep all existing functions from V1
     */
    function deposit() public payable whenNotPaused nonReentrant {
        require(msg.value > 0, "Must send ETH");
        userBalances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) public whenNotPaused nonReentrant {
        require(userBalances[msg.sender] >= amount, "Insufficient balance");
        userBalances[msg.sender] -= amount;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getVersion() public view returns (uint256) {
        return version;
    }

    /// @dev Emitted when value is updated
    event ValueUpdated(uint256 oldValue, uint256 newValue);

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}

/**
 * DEPLOYMENT EXAMPLE (using Hardhat):
 *
 * // Deploy V1
 * const MyContract = await ethers.getContractFactory("MyUpgradeableContract");
 * const proxy = await upgrades.deployProxy(MyContract, [owner.address], {
 *   initializer: "initialize",
 *   kind: "uups"
 * });
 *
 * // Upgrade to V2
 * const MyContractV2 = await ethers.getContractFactory("MyUpgradeableContractV2");
 * const upgraded = await upgrades.upgradeProxy(proxy.address, MyContractV2);
 * await upgraded.initializeV2();
 *
 * DEPLOYMENT EXAMPLE (using Foundry):
 *
 * // Deploy implementation
 * MyUpgradeableContract implementation = new MyUpgradeableContract();
 *
 * // Deploy proxy
 * ERC1967Proxy proxy = new ERC1967Proxy(
 *   address(implementation),
 *   abi.encodeCall(implementation.initialize, (owner))
 * );
 *
 * // Interact via proxy
 * MyUpgradeableContract proxied = MyUpgradeableContract(address(proxy));
 *
 * // Upgrade
 * MyUpgradeableContractV2 implementationV2 = new MyUpgradeableContractV2();
 * proxied.upgradeTo(address(implementationV2));
 * MyUpgradeableContractV2(address(proxy)).initializeV2();
 */
