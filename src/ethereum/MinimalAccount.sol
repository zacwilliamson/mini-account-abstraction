// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {IAccount} from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import {PackedUserOperation} from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// ^^ Where we send all of our data that needs to be packed for the alt mempool

contract MinimalAccount is IAccount, Ownable {
    constructor() Ownable(msg.sender) {}

    //A signature is valid if it's the MinimalAccount owner.
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        // _validateSignature(userOp, userOpHash);
    }
}
