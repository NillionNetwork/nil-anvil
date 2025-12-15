// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BurnWithDigest
 * @notice Wrapper contract for burning NIL ERC-20 tokens with an associated payment digest.
 * @dev Since the NIL ERC-20 contract doesn't have a native burn function with data,
 *      this contract provides that functionality by transferring tokens to the dead address
 *      and emitting an event linking the burn to a payment digest.
 */
contract BurnWithDigest is Ownable {
    using SafeERC20 for IERC20;

    /// @notice The NIL ERC-20 token address
    IERC20 public immutable nilToken;

    /// @notice The dead address where tokens are sent (effectively burned)
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
     * @notice Emitted when tokens are burned with a digest
     * @param payer The address that paid for the burn
     * @param amount The amount of tokens burned (in wei)
     * @param digest The payment digest (Keccak-256 hash of subscription payload)
     * @param timestamp The block timestamp when the burn occurred
     */
    event LogBurnWithDigest(address indexed payer, uint256 amount, bytes32 indexed digest, uint256 timestamp);

    /**
     * @notice Emitted when ERC-20 tokens are rescued by the owner
     * @param token The address of the token that was rescued
     * @param to The address that received the rescued tokens
     * @param amount The amount of tokens rescued
     */
    event TokensRescued(address indexed token, address indexed to, uint256 amount);

    /**
     * @notice Constructor to initialize the contract
     * @param _nilToken The address of the NIL ERC-20 token contract
     */
    constructor(address _nilToken) Ownable(msg.sender) {
        require(_nilToken != address(0), "BurnWithDigest: nil token address cannot be zero");
        nilToken = IERC20(_nilToken);
    }

    /**
     * @notice Burns NIL tokens by transferring them to the dead address and emitting an event with the digest
     * @param amount The amount of NIL tokens to burn (in wei)
     * @param digest The payment digest (Keccak-256 hash of the subscription payload)
     * @dev The caller must have approved this contract to spend at least `amount` tokens
     */
    function burnWithDigest(uint256 amount, bytes32 digest) external {
        require(amount > 0, "BurnWithDigest: amount must be greater than zero");
        require(digest != bytes32(0), "BurnWithDigest: digest cannot be zero");

        // Transfer tokens from the caller to the dead address
        // This will revert if:
        // - The caller doesn't have enough tokens
        // - The caller hasn't approved this contract to spend their tokens
        // - The token transfer fails for any other reason
        bool success = nilToken.transferFrom(msg.sender, DEAD_ADDRESS, amount);
        require(success, "BurnWithDigest: token transfer failed");

        // Emit the event with the payment details
        emit LogBurnWithDigest(msg.sender, amount, digest, block.timestamp);
    }

    /**
     * @notice Rescue ERC-20 tokens that were accidentally sent to this contract
     * @param token The address of the ERC-20 token to rescue
     * @param to The address to send the rescued tokens to
     * @param amount The amount of tokens to rescue
     * @dev Only the contract owner can call this function
     * @dev This is a safety mechanism to recover tokens sent directly to the contract address
     */
    function rescueERC20(address token, address to, uint256 amount) external onlyOwner {
        require(token != address(0), "BurnWithDigest: token address cannot be zero");
        require(to != address(0), "BurnWithDigest: recipient address cannot be zero");
        require(amount > 0, "BurnWithDigest: amount must be greater than zero");

        IERC20(token).safeTransfer(to, amount);

        emit TokensRescued(token, to, amount);
    }
}
