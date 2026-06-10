// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract Web3Escrow {
    enum Status {
        Created,
        Funded,
        Disputed,
        Completed,
        Cancelled
    }

    struct Milestone {
        uint256 amount;
        bytes32 evidenceHash;
        bool approved;
        bool released;
    }

    error NotClient();
    error NotFreelancer();
    error NotParticipant();
    error NotArbiter();
    error InvalidStatus();
    error InvalidMilestone();
    error TransferFailed();
    error AlreadyReleased();
    error NotApproved();
    error InvalidAddress();
    error InvalidInput();
    error Locked();

    IERC20 public immutable token;
    address public immutable client;
    address public immutable freelancer;
    address public immutable arbiter;
    uint256 public immutable totalAmount;

    Status public status;
    uint256 public releasedAmount;
    bool private locked;

    Milestone[] private milestones;

    event Funded(address indexed client, uint256 amount);
    event MilestoneApproved(uint256 indexed milestoneId, bytes32 evidenceHash);
    event MilestoneReleased(uint256 indexed milestoneId, address indexed freelancer, uint256 amount);
    event DisputeOpened(address indexed openedBy, string reason);
    event DisputeResolved(uint256 clientRefund, uint256 freelancerPayout);
    event Cancelled(uint256 refundAmount);

    modifier onlyClient() {
        if (msg.sender != client) revert NotClient();
        _;
    }

    modifier onlyFreelancer() {
        if (msg.sender != freelancer) revert NotFreelancer();
        _;
    }

    modifier onlyParticipant() {
        if (msg.sender != client && msg.sender != freelancer) revert NotParticipant();
        _;
    }

    modifier onlyArbiter() {
        if (msg.sender != arbiter) revert NotArbiter();
        _;
    }

    modifier noReentry() {
        if (locked) revert Locked();
        locked = true;
        _;
        locked = false;
    }

    constructor(
        address token_,
        address freelancer_,
        address arbiter_,
        uint256[] memory amounts_,
        bytes32[] memory evidenceHashes_
    ) {
        if (token_ == address(0) || freelancer_ == address(0) || arbiter_ == address(0)) {
            revert InvalidAddress();
        }
        if (amounts_.length == 0 || amounts_.length != evidenceHashes_.length) revert InvalidInput();

        token = IERC20(token_);
        client = msg.sender;
        freelancer = freelancer_;
        arbiter = arbiter_;
        status = Status.Created;

        uint256 total;
        for (uint256 i = 0; i < amounts_.length; i++) {
            if (amounts_[i] == 0) revert InvalidInput();
            total += amounts_[i];
            milestones.push(
                Milestone({
                    amount: amounts_[i],
                    evidenceHash: evidenceHashes_[i],
                    approved: false,
                    released: false
                })
            );
        }

        totalAmount = total;
    }

    function milestoneCount() external view returns (uint256) {
        return milestones.length;
    }

    function getMilestone(uint256 milestoneId) external view returns (Milestone memory) {
        if (milestoneId >= milestones.length) revert InvalidMilestone();
        return milestones[milestoneId];
    }

    function fund() external onlyClient noReentry {
        if (status != Status.Created) revert InvalidStatus();
        status = Status.Funded;
        if (!token.transferFrom(msg.sender, address(this), totalAmount)) revert TransferFailed();
        emit Funded(msg.sender, totalAmount);
    }

    function approveMilestone(uint256 milestoneId, bytes32 evidenceHash) external onlyClient {
        if (status != Status.Funded) revert InvalidStatus();
        if (milestoneId >= milestones.length) revert InvalidMilestone();

        Milestone storage milestone = milestones[milestoneId];
        if (milestone.released) revert AlreadyReleased();

        milestone.evidenceHash = evidenceHash;
        milestone.approved = true;
        emit MilestoneApproved(milestoneId, evidenceHash);
    }

    function releaseMilestone(uint256 milestoneId) external noReentry {
        if (msg.sender != client && msg.sender != freelancer) revert NotParticipant();
        if (status != Status.Funded) revert InvalidStatus();
        if (milestoneId >= milestones.length) revert InvalidMilestone();

        Milestone storage milestone = milestones[milestoneId];
        if (milestone.released) revert AlreadyReleased();
        if (!milestone.approved) revert NotApproved();

        milestone.released = true;
        releasedAmount += milestone.amount;

        if (!token.transfer(freelancer, milestone.amount)) revert TransferFailed();
        emit MilestoneReleased(milestoneId, freelancer, milestone.amount);

        if (releasedAmount == totalAmount) {
            status = Status.Completed;
        }
    }

    function openDispute(string calldata reason) external onlyParticipant {
        if (status != Status.Funded) revert InvalidStatus();
        status = Status.Disputed;
        emit DisputeOpened(msg.sender, reason);
    }

    function resolveDispute(uint256 clientRefund, uint256 freelancerPayout) external onlyArbiter noReentry {
        if (status != Status.Disputed) revert InvalidStatus();
        uint256 remaining = totalAmount - releasedAmount;
        if (clientRefund + freelancerPayout != remaining) revert InvalidInput();

        status = Status.Completed;

        if (clientRefund > 0 && !token.transfer(client, clientRefund)) revert TransferFailed();
        if (freelancerPayout > 0 && !token.transfer(freelancer, freelancerPayout)) revert TransferFailed();

        emit DisputeResolved(clientRefund, freelancerPayout);
    }

    function cancelBeforeFunding() external onlyClient {
        if (status != Status.Created) revert InvalidStatus();
        status = Status.Cancelled;
        emit Cancelled(0);
    }

    function cancelAndRefund() external onlyClient noReentry {
        if (status != Status.Funded) revert InvalidStatus();

        uint256 refund = totalAmount - releasedAmount;
        status = Status.Cancelled;

        if (refund > 0 && !token.transfer(client, refund)) revert TransferFailed();
        emit Cancelled(refund);
    }
}
