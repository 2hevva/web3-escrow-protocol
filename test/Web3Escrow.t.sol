// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/Web3Escrow.sol";

contract MockUSDC {
    string public constant name = "Mock USDC";
    string public constant symbol = "mUSDC";
    uint8 public constant decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "BALANCE");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "BALANCE");
        require(allowance[from][msg.sender] >= amount, "ALLOWANCE");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract Web3EscrowTest is Test {
    MockUSDC private usdc;
    Web3Escrow private escrow;

    address private client = address(0xC11E);
    address private freelancer = address(0xF411);
    address private arbiter = address(0xA);

    uint256 private constant FIRST = 1_000e6;
    uint256 private constant SECOND = 2_000e6;

    function setUp() public {
        usdc = new MockUSDC();
        usdc.mint(client, FIRST + SECOND);

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = FIRST;
        amounts[1] = SECOND;

        bytes32[] memory evidenceHashes = new bytes32[](2);
        evidenceHashes[0] = keccak256("scope");
        evidenceHashes[1] = keccak256("delivery");

        vm.prank(client);
        escrow = new Web3Escrow(address(usdc), freelancer, arbiter, amounts, evidenceHashes);
    }

    function testClientFundsEscrow() public {
        vm.startPrank(client);
        usdc.approve(address(escrow), FIRST + SECOND);
        escrow.fund();
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(escrow)), FIRST + SECOND);
        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Funded));
    }

    function testApprovedMilestoneCanBeReleased() public {
        _fund();

        vm.prank(client);
        escrow.approveMilestone(0, keccak256("milestone-1-pr"));

        vm.prank(freelancer);
        escrow.releaseMilestone(0);

        assertEq(usdc.balanceOf(freelancer), FIRST);
        assertEq(escrow.releasedAmount(), FIRST);
        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Funded));
    }

    function testCompletesAfterAllMilestonesReleased() public {
        _fund();

        vm.startPrank(client);
        escrow.approveMilestone(0, keccak256("first"));
        escrow.approveMilestone(1, keccak256("second"));
        escrow.releaseMilestone(0);
        escrow.releaseMilestone(1);
        vm.stopPrank();

        assertEq(usdc.balanceOf(freelancer), FIRST + SECOND);
        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Completed));
    }

    function testCannotReleaseUnapprovedMilestone() public {
        _fund();

        vm.prank(freelancer);
        vm.expectRevert(Web3Escrow.NotApproved.selector);
        escrow.releaseMilestone(0);
    }

    function testArbiterResolvesDispute() public {
        _fund();

        vm.prank(freelancer);
        escrow.openDispute("client is unresponsive");

        vm.prank(arbiter);
        escrow.resolveDispute(1_500e6, 1_500e6);

        assertEq(usdc.balanceOf(client), 1_500e6);
        assertEq(usdc.balanceOf(freelancer), 1_500e6);
        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Completed));
    }

    function testClientCanRefundUnreleasedBalance() public {
        _fund();

        vm.prank(client);
        escrow.cancelAndRefund();

        assertEq(usdc.balanceOf(client), FIRST + SECOND);
        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Cancelled));
    }

    function _fund() private {
        vm.startPrank(client);
        usdc.approve(address(escrow), FIRST + SECOND);
        escrow.fund();
        vm.stopPrank();
    }
}
