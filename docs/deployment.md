# Testnet Deployment

This project is designed to be deployed first on Base Sepolia or Sepolia with a mock or testnet ERC-20 token.

## Prerequisites

- Foundry installed
- A funded testnet deployer wallet
- A testnet ERC-20 token address
- RPC URL for the target network
- Optional explorer API key for source verification

## Configure Environment

Copy the example file:

```bash
cp .env.example .env
```

Fill in:

- `PRIVATE_KEY`
- `TOKEN_ADDRESS`
- `FREELANCER_ADDRESS`
- `ARBITER_ADDRESS`
- `MILESTONE_1_AMOUNT`
- `MILESTONE_2_AMOUNT`
- `MILESTONE_1_SCOPE`
- `MILESTONE_2_SCOPE`

Amounts should use the token's smallest unit. For a 6-decimal USDC-like token, `1000000000` means `1,000 USDC`.

## Deploy To Base Sepolia

```bash
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast \
  --verify \
  --etherscan-api-key "$BASESCAN_API_KEY"
```

## Deploy To Sepolia

```bash
source .env
forge script script/Deploy.s.sol:Deploy \
  --rpc-url "$SEPOLIA_RPC_URL" \
  --broadcast \
  --verify \
  --etherscan-api-key "$ETHERSCAN_API_KEY"
```

## Post-Deploy Checklist

- Add the deployed contract address to this README.
- Add the explorer link.
- Save constructor arguments and transaction hash under `deployments/`.
- Connect the frontend to live contract reads.
- Record a short demo showing wallet connection, funding, approval, release, and dispute states.
