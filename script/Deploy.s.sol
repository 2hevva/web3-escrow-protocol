// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Web3Escrow.sol";

contract Deploy is Script {
    function run() external returns (Web3Escrow escrow) {
        address token = vm.envAddress("TOKEN_ADDRESS");
        address freelancer = vm.envAddress("FREELANCER_ADDRESS");
        address arbiter = vm.envAddress("ARBITER_ADDRESS");

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = vm.envUint("MILESTONE_1_AMOUNT");
        amounts[1] = vm.envUint("MILESTONE_2_AMOUNT");

        bytes32[] memory hashes = new bytes32[](2);
        hashes[0] = keccak256(bytes(vm.envString("MILESTONE_1_SCOPE")));
        hashes[1] = keccak256(bytes(vm.envString("MILESTONE_2_SCOPE")));

        vm.startBroadcast();
        escrow = new Web3Escrow(token, freelancer, arbiter, amounts, hashes);
        vm.stopBroadcast();
    }
}
