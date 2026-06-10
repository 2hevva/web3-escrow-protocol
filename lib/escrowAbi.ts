export const escrowAbi = [
  {
    type: "function",
    name: "fund",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  },
  {
    type: "function",
    name: "approveMilestone",
    stateMutability: "nonpayable",
    inputs: [
      { name: "milestoneId", type: "uint256" },
      { name: "evidenceHash", type: "bytes32" }
    ],
    outputs: []
  },
  {
    type: "function",
    name: "releaseMilestone",
    stateMutability: "nonpayable",
    inputs: [{ name: "milestoneId", type: "uint256" }],
    outputs: []
  },
  {
    type: "function",
    name: "openDispute",
    stateMutability: "nonpayable",
    inputs: [{ name: "reason", type: "string" }],
    outputs: []
  },
  {
    type: "function",
    name: "resolveDispute",
    stateMutability: "nonpayable",
    inputs: [
      { name: "clientRefund", type: "uint256" },
      { name: "freelancerPayout", type: "uint256" }
    ],
    outputs: []
  }
] as const;
