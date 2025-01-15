// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; // static version over floating

/**
 * @title Inharitance Contract
 * @author Akash Bansal
 *
 * @notice This contract would allow Owner to withdraw ether and heir to take control of contract in certain conditions
 *
 * Properties/conditions:
 * - Initial owner and heir will be defined in the constructor.
 * - heir can take the contol of contract and assign a new heir whenever the owner has not withdrawn any money within last 30 days.
 * - Owner can withdraw Zero Amount of ether in order to reset the counter of last withdrawn time.
 */
contract Inheritance {
    ////////////////////////
    //Errors             ///
    ////////////////////////

    /**
     * @dev NonZero heir address is required.
     */
    error MustBeNonZeroAddress();

    /**
     * @dev Owner and heir can not be the same Address
     */
    error OwnerAndHeirMustBeDifferent();

    /**
     * @dev caller does not have permission to call this.
     */
    error Unauthorized();
    /**
     * @dev contract does not have enough Funds.
     */
    error InsufficientBalance();
    /**
     * @dev Withdrawl Failed
     */
    error WithdrawalFailed();
    /**
     * @param timeElapsed time elapsed in seconds from last withdrawal
     * Inactivity Period has not been passed yet.
     */
    error InactivityPeriodNotMet(uint256 timeElapsed);

    ///////////////////////
    // CONSTANTS   ////////
    ///////////////////////
    uint256 public constant INACTIVITY_PERIOD = 30 days;

    ////////////////////////
    //   State Variales ////
    ////////////////////////
    address public owner; // visibality is public so no need to create additional getter;
    address public heir;
    uint256 public lastWithdrawalTime;

    ///////////////////////
    // Events            //
    ////////////////////////

    /**
     *
     * @param from Eth Deposited from the Account
     * @param amount Amounted deposited
     */
    event EthDeposited(address indexed from, uint256 amount);

    /**
     *
     * @param to Amount is transferred to this Account.
     * @param amount Amount that is transferred.
     * @param newLastWithdrawalTime New timestamp for last withdrawal.
     */
    event WithdrawalCompletedAndTimeUpdated(address indexed to, uint256 amount, uint256 newLastWithdrawalTime);

    /**
     * @param oldOwner is the Owner of this Inheritance contract Before the Inheritance states upddates.
     * @param newOwner is the new Owner of this Inheritance contract After the Inheritance states upddates.
     * @param newHeir is the new Heir of this Inheritance contract After the Inheritance states upddates.
     * @param newLastWithdrawalTime is the new Last Withdrawal Time of this Inheritance contract After the state update.
     */
    event InheritanceStateUpdated(
        address indexed oldOwner, address indexed newOwner, address indexed newHeir, uint256 newLastWithdrawalTime
    );

    ////////////////////////
    //Modifiers          //
    ////////////////////////

    /**
     * @notice to check If heir address is zero Address
     * @notice to check If new heir address is not same as owner address to eliminate self inheritance
     * @param _address to check
     */
    modifier heirAddressCheck(address _address) {
        if (_address == address(0)) {
            revert MustBeNonZeroAddress();
        }

        if (_address == msg.sender) revert OwnerAndHeirMustBeDifferent();
        _;
    }
    /**
     *
     * @notice to check if the account is the owner
     */

    ////////////////////////
    //   Constructor     //
    ///////////////////////

    /**
     * @notice Initializes the `owner`, `heir` and `lastWithdrawalTime`;
     *
     * @param _heir Address of heir for initlial configuration of the contract.
     *
     * @dev `_heir` Address should be non Zero such that heir can take control over a month.
     * Since there is no transfer ownership function so Zero heir Address may stuck ownership and thus no point of Inheritance.
     *
     * @dev We are assuming that we are staring one month time from contract deployment time till the first Reset.
     */
    constructor(address _heir) payable heirAddressCheck(_heir) {
        owner = msg.sender;
        heir = _heir;
        lastWithdrawalTime = block.timestamp;
        if (msg.value > 0) {
            emit EthDeposited(msg.sender, msg.value);
        }
    }

    /**
     * @notice Fallback function to allow receiving Ether and Emits `EthDeposited` event
     */
    receive() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @notice An Explicit way to send Ether to the contract.
     * @dev This function can be ommited to save deployment cost, but we are prfereing to make an easy deposit interface.
     */
    function deposit() external payable {
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Only owner can withdraw Amount and sets new `lastWithdrawalTime` and Emits Withdrawl Event
     * @param amount in wei to be withdrawn by the owner
     * @dev Zero Amount is acceptable to Reset the `lastWithdrawalTime`. This is useful when the owner wants to reset the withdrawal time.
     * @dev CEI (Check Effect Interatcion is followed)
     */
    function withdraw(uint256 amount) external {
        if (msg.sender != owner) revert Unauthorized();
        if (amount > address(this).balance) {
            revert InsufficientBalance();
        }
        lastWithdrawalTime = block.timestamp;
        emit WithdrawalCompletedAndTimeUpdated(msg.sender, amount, lastWithdrawalTime);
        if (amount > 0) {
            (bool success,) = payable(owner).call{value: amount}("");
            if (!success) {
                revert WithdrawalFailed();
            }
        }
    }

    /**
     * @notice checks for New hier Address and Inactivity Condition and If Met then sets new owner and new Heir and Emits Event.
     * @notice Resets this contract's `lastWithdrawalTime` to the current block timestamp.
     * @param newHeir Adddress to be assigned for New Heir after taking control by present heir.
     *
     */
    function claimOwnership(address newHeir) external heirAddressCheck(newHeir) {
        if (msg.sender != heir) {
            revert Unauthorized();
        }
        uint256 timeElapsed = block.timestamp - lastWithdrawalTime;

        if (timeElapsed <= INACTIVITY_PERIOD) {
            revert InactivityPeriodNotMet(timeElapsed);
        }
        address _oldOwner = owner;
        owner = msg.sender;
        heir = newHeir;
        lastWithdrawalTime = block.timestamp; // Reset the last withdrawal time

        emit InheritanceStateUpdated(_oldOwner, owner, newHeir, lastWithdrawalTime);
    }
}
