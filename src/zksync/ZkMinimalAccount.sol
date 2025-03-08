// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IAccount} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {
    Transaction,
    MemoryTransactionHelper
} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from
    "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/SystemContractsCaller.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "lib/foundry-era-contracts/src/system-contracts/contracts/Constants.sol";
import {INonceHolder} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/INonceHolder.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    IAccount,
    ACCOUNT_VALIDATION_SUCCESS_MAGIC
} from "lib/foundry-era-contracts/src/system-contracts/contracts/interfaces/IAccount.sol";
import {Utils} from "lib/foundry-era-contracts/src/system-contracts/contracts/libraries/Utils.sol";

// In ZkSync, every EoA (metamask type accounts) are smart contract wallets
/**
 * Lifecycle of a type 113 (0x71) transaction
 * msg.sender is the bootloader system contract (similar to entrypoint)
 * **Phase 1: Validation**
 *
 *     1. The user sends the transaction to the "ZKsync API client" (sort of a "light node").
 *     2. The ZKsync API client checks to see that the nonce is unique by querying the `NonceHolder` system contract.
 *     3. The ZKsync API client calls `validateTransaction`, which MUST update the nonce.
 *     4. The ZKsync API client checks the nonce is updated.
 *     5. The ZKsync API client calls `payForTransaction`, or `prepareForPaymaster` & `validateAndPayForPaymasterTransaction`.
 *     6. The ZKsync API client verifies that the bootloader gets paid.
 *
 * Phase 2: Execution**
 *
 *     1. The ZKsync API client passes the validated transaction to the main node / sequencer (as of today, they are the same).
 *     2. The main node calls `executeTransaction`.
 *     3. If a paymaster was used, the `postTransaction` is called.
 */
contract ZkMinimalAccount is IAccount, Ownable {
    using MemoryTransactionHelper for Transaction;

    /*//////////////////////////////////////////////////////////////
                                 ERROR
    //////////////////////////////////////////////////////////////*/
    error ZkMinimalAccount__NotEnoughBalance();
    error ZkMinimalAccount__NotFromBootLoader();
    error ZkMinimalAccount__ExecutionFailed();
    error ZkMinimalAccount__NotFromBootLoaderOrOwner();
    error ZkMinimalAccount__FailedToPay();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier requireFromBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert ZkMinimalAccount__NotFromBootLoader();
        }
        _;
    }

    modifier requireFromBootLoaderOrOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert ZkMinimalAccount__NotFromBootLoaderOrOwner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor() Ownable(msg.sender) {}

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice must increase the nonce
     * @notice must validate the transaction (check the owner signed the transaction)
     * @notice also check to see if we have enough money in our account
     * @notice Only the bootloader can use this function
     */
    function validateTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable requireFromBootLoader returns (bytes4 magic) {
        return _validateTransaction(_transaction);
    }

    function executeTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable {
        _executeTransaction(_transaction);
    }

    // can be called from any user that wants to pay for the transaction
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {
        _validateTransaction(_transaction);
        _executeTransaction(_transaction);
    }

    function payForTransaction(
        bytes32, /* _txHash */
        bytes32, /* _suggestedSignedHash */
        Transaction memory _transaction
    ) external payable {
        bool success = _transaction.payToTheBootloader();
        if (!success) {
            revert ZkMinimalAccount__FailedToPay();
        }
    }

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction memory _transaction)
        external
        payable
    {}

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _validateTransaction(Transaction memory _transaction) internal returns (bytes4 magic) {
        // Call NonceHolder
        // increment nonce by 1
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, _transaction.nonce)
        );

        // Check for fee to pay
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert ZkMinimalAccount__NotEnoughBalance();
        }

        // Check the signature
        bytes32 txHash = _transaction.encodeHash();
        address signer = ECDSA.recover(txHash, _transaction.signature);
        bool isValidSigner = signer == owner();
        if (isValidSigner) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }
        // return the "magic" number
        return magic;
    }

    function _executeTransaction(Transaction memory _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint128 value = Utils.safeCastToU128(_transaction.value);
        bytes memory data = _transaction.data;

        if (to == address(DEPLOYER_SYSTEM_CONTRACT)) {
            uint32 gas = Utils.safeCastToU32(gasleft());
            SystemContractsCaller.systemCallWithPropagatedRevert(gas, to, value, data);
        } else {
            bool success;
            assembly {
                success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
            }
            if (!success) {
                revert ZkMinimalAccount__ExecutionFailed();
            }
        }
    }
}
