// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title ZARStablecoin
 * @dev A South African Rand (ZAR) pegged stablecoin
 * This is a basic implementation - in production, additional security measures
 * and compliance features would be required
 */
contract ZARStablecoin is ERC20, Ownable, Pausable {
    // Address that can mint and burn tokens
    address public minter;

    // Maximum supply cap (set based on ZAR reserves)
    uint256 public maxSupply;

    // Event emitted when minter is updated
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);

    // Event emitted when max supply is updated
    event MaxSupplyUpdated(uint256 oldMaxSupply, uint256 newMaxSupply);

    // Event emitted when tokens are minted
    event TokensMinted(address indexed to, uint256 amount);

    // Event emitted when tokens are burned
    event TokensBurned(address indexed account, uint256 amount);

    constructor(uint256 _maxSupply) ERC20("ZAR Stablecoin", "ZARX") {
        maxSupply = _maxSupply;
        minter = msg.sender;
    }

    /**
     * @dev Modifier to restrict function access to minter
     */
    modifier onlyMinter() {
        require(msg.sender == minter, "ZARStablecoin: caller is not the minter");
        _;
    }

    /**
     * @dev Pauses all token transfers, minting, and burning
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers, minting, and burning
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Updates the minter address
     * @param newMinter The new address with mint/burn privileges
     */
    function updateMinter(address newMinter) external onlyOwner {
        require(newMinter != address(0), "ZARStablecoin: new minter is the zero address");
        emit MinterUpdated(minter, newMinter);
        minter = newMinter;
    }

    /**
     * @dev Updates the maximum supply
     * @param newMaxSupply The new maximum supply cap
     */
    function updateMaxSupply(uint256 newMaxSupply) external onlyOwner {
        require(totalSupply() <= newMaxSupply, "ZARStablecoin: total supply exceeds new max supply");
        emit MaxSupplyUpdated(maxSupply, newMaxSupply);
        maxSupply = newMaxSupply;
    }

    /**
     * @dev Mints new tokens up to the max supply limit
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyMinter whenNotPaused {
        require(totalSupply() + amount <= maxSupply, "ZARStablecoin: minting would exceed max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    /**
     * @dev Burns tokens from the caller's account
     * @param amount The amount of tokens to burn
     */
    function burn(uint256 amount) external whenNotPaused {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }

    /**
     * @dev Burns tokens from a specific account
     * @param account The account to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external whenNotPaused {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ZARStablecoin: burn amount exceeds allowance");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
        emit TokensBurned(account, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}