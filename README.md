# About

1. Create minimal Account Abstraction on Ethereum
2. Create minimal Account Abstraction on ZKsync
3. Deploy and send a userOp/transaction through them
    1. Not going to send an AA to Ethereum
    2. But we will send an AA tx to zksync

## Notes 

### Account Abstraction

#### Overview

Account Abstraction simplifies the process of signing transactions by eliminating the need for private keys. Instead, users can leverage different types of keys that are more secure and user-friendly.

## Importance of Account Abstraction

Account abstraction allows users to sign transactions without the use of private keys. This makes the process more accessible and secure by offering alternative signing mechanisms.

## How Account Abstraction Solves Common Problems

Account abstraction addresses the following issues related to private key management and transaction validation:
- **Simplifies the signing process**: No need to rely on traditional private keys.
- **Reduces risk**: By providing a more secure and user-friendly method for transaction signing, the risk of losing access to an account is minimized.
- **Improves user experience**: Account abstraction enables a smoother and more intuitive experience for users interacting with blockchain networks.

---

## Implementations of Account Abstraction

### 1. Ethereum (EntryPoint.sol)

Ethereum implements account abstraction through the smart contract **EntryPoint.sol**. This contract acts as a gateway for handling user operations and transactions in a more flexible and customizable manner.

### 2. ZKsync

ZKsync integrates account abstraction directly into its codebase. This native integration simplifies the process for developers and users alike.

---

## Role of Alt Mempools in Account Abstraction

In Ethereum, **alt mempools** are used to validate transactions outside the main blockchain network. This reduces congestion, improving overall efficiency and transaction processing speed.

---

## Optional Components in Ethereum's EntryPoint.sol

### 1. Signature Aggregator
The **Signature Aggregator** allows for the aggregation and verification of multiple signatures. This means:
- Multiple users can sign transactions for the same wallet.
- Multi-signature logic can be added, requiring several signatures before a transaction is authorized.

### 2. Paymaster
The **Paymaster** component handles gas payments and gives users the ability to pay for transactions in various ways, not limited to the native cryptocurrency.

---

## Private Key & Wallet Issues

### 1. Private Keys are Hard to Manage
- Private key management is complex and prone to user error.

### 2. Gas Fees for Every Action
- Every action on the blockchain requires gas, creating friction for users.

### 3. Privacy Concerns
- Maintaining privacy with traditional wallets is difficult.

### 4. Multiple Transactions Require Separate Contracts
- For multiple transactions, additional smart contracts are needed.

---

## Traditional Transaction vs. Account Abstraction

### Traditional Transaction
- Requires a private key to sign the transaction.

### Account Abstraction
- Transactions can be signed with **anything**, such as:
  - Google Account
  - GitHub Account

---

## Ethereum Account Abstraction Transaction (ERC-4337)

### 1. Deploy a Smart Contract
To utilize account abstraction, deploy a smart contract that defines **what** can sign transactions. This can be a smart contract wallet.

### 2. User Operations (UserOp)
To send a transaction, you submit a **UserOp** (User Operation), which specifies the action and conditions for the transaction.
