// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Test.sol";
import "../src/BurnWithDigest.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title NIL
 * @notice Test NIL token that mimics mainnet (has burn, no burnWithDigest)
 */
contract NIL is ERC20, ERC20Burnable {
    constructor() ERC20("NIL", "NIL") {
        _mint(msg.sender, 1000000 * 10 ** 18); // Mint 1M tokens
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title BurnWithDigestTest
 * @notice Test suite for the BurnWithDigest contract
 */
contract BurnWithDigestTest is Test {
    BurnWithDigest public burnContract;
    NIL public nilToken;

    address public owner;
    address public user1;
    address public user2;

    // Test constants
    uint256 constant BURN_AMOUNT = 1000 * 10 ** 18; // 1000 tokens
    bytes32 constant TEST_DIGEST = keccak256("test_payment_digest");
    address constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event LogBurnWithDigest(address indexed payer, uint256 amount, bytes32 indexed digest, uint256 timestamp);

    event TokensRescued(address indexed token, address indexed to, uint256 amount);

    function setUp() public {
        // Set up test addresses
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // Deploy mock NIL token
        nilToken = new NIL();

        // Deploy BurnWithDigest contract
        burnContract = new BurnWithDigest(address(nilToken));

        // Give user1 some tokens
        nilToken.mint(user1, 10000 * 10 ** 18);
    }

    function testConstructor() public {
        assertEq(address(burnContract.nilToken()), address(nilToken));
        assertEq(burnContract.owner(), owner);
        assertEq(burnContract.DEAD_ADDRESS(), DEAD_ADDRESS);
    }

    function testConstructorRevertsWithZeroAddress() public {
        vm.expectRevert("BurnWithDigest: nil token address cannot be zero");
        new BurnWithDigest(address(0));
    }

    function testBurnWithDigestSuccess() public {
        // Arrange: user1 approves the burn contract
        vm.startPrank(user1);
        nilToken.approve(address(burnContract), BURN_AMOUNT);

        uint256 userBalanceBefore = nilToken.balanceOf(user1);
        uint256 deadBalanceBefore = nilToken.balanceOf(DEAD_ADDRESS);

        // Expect the LogBurnWithDigest event
        vm.expectEmit(true, true, false, true);
        emit LogBurnWithDigest(user1, BURN_AMOUNT, TEST_DIGEST, block.timestamp);

        // Act: burn tokens
        burnContract.burnWithDigest(BURN_AMOUNT, TEST_DIGEST);
        vm.stopPrank();

        // Assert: check balances and that tokens were "burned"
        assertEq(nilToken.balanceOf(user1), userBalanceBefore - BURN_AMOUNT);
        assertEq(nilToken.balanceOf(DEAD_ADDRESS), deadBalanceBefore + BURN_AMOUNT);
    }

    function testBurnWithDigestRevertsWithZeroAmount() public {
        vm.startPrank(user1);
        vm.expectRevert("BurnWithDigest: amount must be greater than zero");
        burnContract.burnWithDigest(0, TEST_DIGEST);
        vm.stopPrank();
    }

    function testBurnWithDigestRevertsWithZeroDigest() public {
        vm.startPrank(user1);
        nilToken.approve(address(burnContract), BURN_AMOUNT);

        vm.expectRevert("BurnWithDigest: digest cannot be zero");
        burnContract.burnWithDigest(BURN_AMOUNT, bytes32(0));
        vm.stopPrank();
    }

    function testBurnWithDigestRevertsWithoutApproval() public {
        vm.startPrank(user1);
        // Don't approve - should revert
        vm.expectRevert();
        burnContract.burnWithDigest(BURN_AMOUNT, TEST_DIGEST);
        vm.stopPrank();
    }

    function testBurnWithDigestRevertsWithInsufficientBalance() public {
        uint256 excessiveAmount = nilToken.balanceOf(user1) + 1;

        vm.startPrank(user1);
        nilToken.approve(address(burnContract), excessiveAmount);

        vm.expectRevert();
        burnContract.burnWithDigest(excessiveAmount, TEST_DIGEST);
        vm.stopPrank();
    }

    function testMultipleBurnsWithDifferentDigests() public {
        bytes32 digest1 = keccak256("payment1");
        bytes32 digest2 = keccak256("payment2");
        uint256 amount1 = 500 * 10 ** 18;
        uint256 amount2 = 300 * 10 ** 18;

        vm.startPrank(user1);
        nilToken.approve(address(burnContract), amount1 + amount2);

        // First burn
        vm.expectEmit(true, true, false, true);
        emit LogBurnWithDigest(user1, amount1, digest1, block.timestamp);
        burnContract.burnWithDigest(amount1, digest1);

        // Second burn
        vm.expectEmit(true, true, false, true);
        emit LogBurnWithDigest(user1, amount2, digest2, block.timestamp);
        burnContract.burnWithDigest(amount2, digest2);

        vm.stopPrank();

        // Verify total burned
        assertEq(nilToken.balanceOf(DEAD_ADDRESS), amount1 + amount2);
    }

    function testRescueERC20Success() public {
        // Arrange: send some tokens directly to the contract (simulating accidental transfer)
        NIL otherToken = new NIL();
        uint256 rescueAmount = 100 * 10 ** 18;
        otherToken.transfer(address(burnContract), rescueAmount);

        assertEq(otherToken.balanceOf(address(burnContract)), rescueAmount);
        assertEq(otherToken.balanceOf(user2), 0);

        // Expect the TokensRescued event
        vm.expectEmit(true, true, false, true);
        emit TokensRescued(address(otherToken), user2, rescueAmount);

        // Act: rescue the tokens
        burnContract.rescueERC20(address(otherToken), user2, rescueAmount);

        // Assert: check tokens were rescued
        assertEq(otherToken.balanceOf(address(burnContract)), 0);
        assertEq(otherToken.balanceOf(user2), rescueAmount);
    }

    function testRescueERC20RevertsForNonOwner() public {
        NIL otherToken = new NIL();
        uint256 rescueAmount = 100 * 10 ** 18;
        otherToken.transfer(address(burnContract), rescueAmount);

        vm.startPrank(user1);
        vm.expectRevert();
        burnContract.rescueERC20(address(otherToken), user2, rescueAmount);
        vm.stopPrank();
    }

    function testRescueERC20RevertsWithZeroTokenAddress() public {
        vm.expectRevert("BurnWithDigest: token address cannot be zero");
        burnContract.rescueERC20(address(0), user2, 100);
    }

    function testRescueERC20RevertsWithZeroRecipient() public {
        NIL otherToken = new NIL();
        vm.expectRevert("BurnWithDigest: recipient address cannot be zero");
        burnContract.rescueERC20(address(otherToken), address(0), 100);
    }

    function testRescueERC20RevertsWithZeroAmount() public {
        NIL otherToken = new NIL();
        vm.expectRevert("BurnWithDigest: amount must be greater than zero");
        burnContract.rescueERC20(address(otherToken), user2, 0);
    }

    // Fuzz testing
    function testFuzzBurnWithDigest(uint256 amount, bytes32 digest) public {
        // Bound the amount to reasonable values
        amount = bound(amount, 1, nilToken.balanceOf(user1));
        vm.assume(digest != bytes32(0));

        vm.startPrank(user1);
        nilToken.approve(address(burnContract), amount);

        uint256 deadBalanceBefore = nilToken.balanceOf(DEAD_ADDRESS);

        burnContract.burnWithDigest(amount, digest);

        assertEq(nilToken.balanceOf(DEAD_ADDRESS), deadBalanceBefore + amount);
        vm.stopPrank();
    }
}
