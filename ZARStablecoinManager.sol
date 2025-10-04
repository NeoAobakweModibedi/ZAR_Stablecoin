// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ZARStablecoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ZARStablecoinManager
 * @dev Manages the ZAR stablecoin minting and burning operations
 * This contract handles the process of minting tokens when ZAR is deposited
 * and burning tokens when ZAR is redeemed
 */
contract ZARStablecoinManager is Ownable, ReentrancyGuard {
    // The ZAR stablecoin contract
    ZARStablecoin public stablecoin;

    // Address of the authorized operator who can process mint/burn requests
    address public authorizedOperator;

    // Mapping to track mint requests
    mapping(uint256 => MintRequest) public mintRequests;
    uint256 public mintRequestCounter;

    // Mapping to track burn requests
    mapping(uint256 => BurnRequest) public burnRequests;
    uint256 public burnRequestCounter;

    // Struct for mint requests
    struct MintRequest {
        address requester;
        uint256 amount;
        address recipient;
        bool processed;
        bool approved;
        uint256 timestamp;
    }

    // Struct for burn requests
    struct BurnRequest {
        address requester;
        uint256 amount;
        bool processed;
        bool approved;
        uint256 timestamp;
    }

    // Event emitted when a mint request is created
    event MintRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint256 amount,
        address recipient
    );

    // Event emitted when a mint request is processed
    event MintProcessed(
        uint256 indexed requestId,
        address indexed requester,
        uint256 amount,
        bool approved
    );

    // Event emitted when a burn request is created
    event BurnRequested(
        uint256 indexed requestId,
        address indexed requester,
        uint256 amount
    );

    // Event emitted when a burn request is processed
    event BurnProcessed(
        uint256 indexed requestId,
        address indexed requester,
        uint256 amount,
        bool approved
    );

    // Event emitted when the authorized operator is updated
    event AuthorizedOperatorUpdated(
        address indexed oldOperator,
        address indexed newOperator
    );

    // Event emitted when the stablecoin contract is set
    event StablecoinContractUpdated(address indexed oldContract, address indexed newContract);

    constructor(address _stablecoinAddress) {
        require(_stablecoinAddress != address(0), "ZARStablecoinManager: stablecoin address is zero");
        stablecoin = ZARStablecoin(_stablecoinAddress);
        authorizedOperator = msg.sender;
    }

    /**
     * @dev Modifier to restrict function access to authorized operator
     */
    modifier onlyAuthorizedOperator() {
        require(
            msg.sender == authorizedOperator,
            "ZARStablecoinManager: caller is not the authorized operator"
        );
        _;
    }

    /**
     * @dev Creates a request to mint new stablecoins
     * This function would be called after receiving ZAR off-chain
     * @param amount The amount of stablecoins to mint
     * @param recipient The address to receive the minted stablecoins
     */
    function requestMint(uint256 amount, address recipient) external nonReentrant returns (uint256) {
        require(amount > 0, "ZARStablecoinManager: amount must be greater than 0");
        require(recipient != address(0), "ZARStablecoinManager: recipient is the zero address");

        uint256 requestId = mintRequestCounter++;
        mintRequests[requestId] = MintRequest({
            requester: msg.sender,
            amount: amount,
            recipient: recipient,
            processed: false,
            approved: false,
            timestamp: block.timestamp
        });

        emit MintRequested(requestId, msg.sender, amount, recipient);
        return requestId;
    }

    /**
     * @dev Processes a mint request
     * This function would be called after verifying ZAR deposit off-chain
     * @param requestId The ID of the mint request to process
     * @param approve Whether to approve or reject the request
     */
    function processMintRequest(uint256 requestId, bool approve) 
        external 
        onlyAuthorizedOperator 
        nonReentrant 
    {
        require(requestId < mintRequestCounter, "ZARStablecoinManager: invalid request ID");
        MintRequest storage request = mintRequests[requestId];
        require(!request.processed, "ZARStablecoinManager: request already processed");

        request.processed = true;
        request.approved = approve;

        if (approve) {
            stablecoin.mint(request.recipient, request.amount);
        }

        emit MintProcessed(requestId, request.requester, request.amount, approve);
    }

    /**
     * @dev Creates a request to burn stablecoins
     * @param amount The amount of stablecoins to burn
     */
    function requestBurn(uint256 amount) external nonReentrant returns (uint256) {
        require(amount > 0, "ZARStablecoinManager: amount must be greater than 0");
        require(
            stablecoin.balanceOf(msg.sender) >= amount,
            "ZARStablecoinManager: insufficient balance"
        );

        // Transfer tokens to this contract for burning
        stablecoin.transferFrom(msg.sender, address(this), amount);

        uint256 requestId = burnRequestCounter++;
        burnRequests[requestId] = BurnRequest({
            requester: msg.sender,
            amount: amount,
            processed: false,
            approved: false,
            timestamp: block.timestamp
        });

        emit BurnRequested(requestId, msg.sender, amount);
        return requestId;
    }

    /**
     * @dev Processes a burn request
     * This function would be called after verifying ZAR redemption off-chain
     * @param requestId The ID of the burn request to process
     * @param approve Whether to approve or reject the request
     */
    function processBurnRequest(uint256 requestId, bool approve)
        external
        onlyAuthorizedOperator
        nonReentrant
    {
        require(requestId < burnRequestCounter, "ZARStablecoinManager: invalid request ID");
        BurnRequest storage request = burnRequests[requestId];
        require(!request.processed, "ZARStablecoinManager: request already processed");

        request.processed = true;
        request.approved = approve;

        if (approve) {
            // Burn the tokens held by this contract
            IERC20(stablecoin).approve(address(stablecoin), request.amount);
            stablecoin.burn(request.amount);
            // In a real implementation, the ZAR would be sent to the requester off-chain
        } else {
            // Return tokens to the requester if request is rejected
            IERC20(stablecoin).transfer(request.requester, request.amount);
        }

        emit BurnProcessed(requestId, request.requester, request.amount, approve);
    }

    /**
     * @dev Updates the authorized operator
     * @param newOperator The new authorized operator address
     */
    function updateAuthorizedOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "ZARStablecoinManager: new operator is the zero address");
        emit AuthorizedOperatorUpdated(authorizedOperator, newOperator);
        authorizedOperator = newOperator;
    }

    /**
     * @dev Updates the stablecoin contract address
     * @param newStablecoin The new stablecoin contract address
     */
    function updateStablecoinContract(address newStablecoin) external onlyOwner {
        require(newStablecoin != address(0), "ZARStablecoinManager: new stablecoin is the zero address");
        emit StablecoinContractUpdated(address(stablecoin), newStablecoin);
        stablecoin = ZARStablecoin(newStablecoin);
    }

    /**
     * @dev Allows the owner to withdraw any accidentally sent ERC20 tokens
     * @param tokenAddress The address of the ERC20 token to withdraw
     * @param amount The amount to withdraw
     */
    function recoverERC20(address tokenAddress, uint256 amount) external onlyOwner {
        IERC20(tokenAddress).transfer(owner(), amount);
    }
}