# ZAR Stablecoin (ZARX)

A South African Rand (ZAR) pegged stablecoin implementation designed for the South African market.

## Overview

ZARX is a fiat-backed stablecoin designed to maintain a 1:1 peg with the South African Rand (ZAR). This implementation follows best practices for stablecoin design with security, transparency, and regulatory compliance in mind.

## Architecture

The system consists of two main smart contracts:

1. **ZARStablecoin.sol** - The main ERC-20 token contract
   - Implements standard ERC-20 functionality
   - Has mint and burn capabilities for authorized addresses
   - Includes pausable functionality for emergency situations
   - Enforces a maximum supply cap

2. **ZARStablecoinManager.sol** - The management contract
   - Handles mint and burn request workflows
   - Provides approval mechanisms for requests
   - Interfaces between users and the stablecoin contract

## Key Features

- **Security**: Access controls, pausable functionality, and reentrancy protection
- **Transparency**: Request tracking with approval processes
- **Regulatory Considerations**: Designed with South African financial regulations in mind
- **Scalability**: Framework designed to handle high transaction volumes

## Contract Functions

### ZARStablecoin
- `mint(address to, uint256 amount)` - Mints new tokens (only minter)
- `burn(uint256 amount)` - Burns tokens from caller's account
- `burnFrom(address account, uint256 amount)` - Burns tokens from specific account
- `pause()` - Pauses all token transfers (only owner)
- `updateMinter(address newMinter)` - Updates the minter address (only owner)

### ZARStablecoinManager
- `requestMint(uint256 amount, address recipient)` - Requests to mint new tokens
- `processMintRequest(uint256 requestId, bool approve)` - Processes mint requests
- `requestBurn(uint256 amount)` - Requests to burn tokens
- `processBurnRequest(uint256 requestId, bool approve)` - Processes burn requests

## Design Considerations

1. **Reserve Management**: Designed to interface with off-chain ZAR reserves
2. **Regulatory Compliance**: Framework for AML/KYC compliance
3. **Audit Trail**: All mint and burn operations are logged with events
4. **Emergency Procedures**: Pausable functionality to halt operations if needed

## Requirements

- Solidity ^0.8.0
- OpenZeppelin Contracts

## Deployment

The contracts should be deployed in the following order:
1. Deploy ZARStablecoin with an appropriate max supply
2. Deploy ZARStablecoinManager with the ZARStablecoin contract address

## Regulatory Compliance

This implementation considers South African financial regulations including:
- Financial Intelligence Centre Act (FICA) requirements
- Anti-Money Laundering (AML) and Know Your Customer (KYC) procedures
- South African Reserve Bank (SARB) guidelines for stablecoins

## Security

This implementation includes:
- Access controls limiting sensitive functions
- Reentrancy protection for value transfers
- Pausable functionality for emergency situations
- Proper input validation

## Disclaimer

This is a proof-of-concept implementation for educational and presentation purposes. 
Before deploying in a production environment, it should undergo:
- Comprehensive security audits
- Legal review of regulatory compliance
- Extensive testing in a testnet environment