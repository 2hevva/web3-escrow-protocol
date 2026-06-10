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

    function testOnlyClientCanFund() public {
        vm.prank(freelancer);
        vm.expectRevert(Web3Escrow.NotClient.selector);
        escrow.fund();
    }

    function testCannotFundTwice() public {
        _fund();

        vm.startPrank(client);
        usdc.approve(address(escrow), FIRST + SECOND);
        vm.expectRevert(Web3Escrow.InvalidStatus.selector);
        escrow.fund();
        vm.stopPrank();
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

    function testOnlyClientCanApproveMilestone() public {
        _fund();

        vm.prank(freelancer);
        vm.expectRevert(Web3Escrow.NotClient.selector);
        escrow.approveMilestone(0, keccak256("not-client"));
    }

    function testCannotApproveInvalidMilestone() public {
        _fund();

        vm.prank(client);
        vm.expectRevert(Web3Escrow.InvalidMilestone.selector);
        escrow.approveMilestone(99, keccak256("missing"));
    }

    function testCannotReleaseInvalidMilestone() public {
        _fund();

        vm.prank(freelancer);
        vm.expectRevert(Web3Escrow.InvalidMilestone.selector);
        escrow.releaseMilestone(99);
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

    function testOnlyParticipantCanOpenDispute() public {
        _fund();

        vm.prank(arbiter);
        vm.expectRevert(Web3Escrow.NotParticipant.selector);
        escrow.openDispute("not a participant");
    }

    function testOnlyArbiterCanResolveDispute() public {
        _fund();

        vm.prank(client);
        escrow.openDispute("scope disagreement");

        vm.prank(client);
        vm.expectRevert(Web3Escrow.NotArbiter.selector);
        escrow.resolveDispute(1_500e6, 1_500e6);
    }

    function testDisputeResolutionMustMatchRemainingBalance() public {
        _fund();

        vm.prank(freelancer);
        escrow.openDispute("client is unresponsive");

        vm.prank(arbiter);
        vm.expectRevert(Web3Escrow.InvalidInput.selector);
        escrow.resolveDispute(1_000e6, 1_000e6);
    }

    function testClientCanRefundUnreleasedBalance() public {
        _fund();

        vm.prank(client);
        escrow.cancelAndRefund();

        assertEq(usdc.balanceOf(client), FIRST + SECOND);
        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Cancelled));
    }

    function testClientCanCancelBeforeFunding() public {
        vm.prank(client);
        escrow.cancelBeforeFunding();

        assertEq(uint256(escrow.status()), uint256(Web3Escrow.Status.Cancelled));
    }

    function testCannotRefundBeforeFunding() public {
        vm.prank(client);
        vm.expectRevert(Web3Escrow.InvalidStatus.selector);
        escrow.cancelAndRefund();
    }

    function testConstructorRejectsInvalidInputs() public {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = FIRST;

        bytes32[] memory hashes = new bytes32[](1);
        hashes[0] = keccak256("scope");

        vm.expectRevert(Web3Escrow.InvalidAddress.selector);
        new Web3Escrow(address(0), freelancer, arbiter, amounts, hashes);

        vm.expectRevert(Web3Escrow.InvalidAddress.selector);
        new Web3Escrow(address(usdc), address(0), arbiter, amounts, hashes);

        uint256[] memory emptyAmounts = new uint256[](0);
        bytes32[] memory emptyHashes = new bytes32[](0);
        vm.expectRevert(Web3Escrow.InvalidInput.selector);
        new Web3Escrow(address(usdc), freelancer, arbiter, emptyAmounts, emptyHashes);

        bytes32[] memory mismatchedHashes = new bytes32[](2);
        vm.expectRevert(Web3Escrow.InvalidInput.selector);
        new Web3Escrow(address(usdc), freelancer, arbiter, amounts, mismatchedHashes);

        amounts[0] = 0;
        vm.expectRevert(Web3Escrow.InvalidInput.selector);
        new Web3Escrow(address(usdc), freelancer, arbiter, amounts, hashes);
    }

    function _fund() private {
        vm.startPrank(client);
        usdc.approve(address(escrow), FIRST + SECOND);
        escrow.fund();
        vm.stopPrank();
    }
}
