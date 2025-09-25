# RareAssets Smart Contract

A decentralized synthetic trading platform for rare metals, vintage wines, and luxury collectibles built on the Stacks blockchain using Clarity.

## Overview

RareAssets enables users to gain synthetic exposure to rare and luxury assets without the need to physically own or store them. The platform uses STX as collateral and allows users to trade synthetic positions in three asset categories:

- **Rare Metals** (Gold, Silver, Platinum, etc.)
- **Vintage Wines** (Fine wine collections)
- **Luxury Collectibles** (Art, watches, rare items)

## Features

### Core Functionality
- ✅ Synthetic asset creation and management
- ✅ STX collateral-based trading system
- ✅ Long position opening and closing
- ✅ Real-time price updates by oracle (contract owner)
- ✅ Protocol fee system (0.25% default)
- ✅ Emergency pause/reactivate mechanism

### Security Features
- ✅ Owner-only administrative functions
- ✅ Comprehensive input validation
- ✅ Balance verification on all operations
- ✅ Error handling with descriptive error codes

## Contract Architecture

### Constants
- `RARE-METALS`: Asset type identifier (1)
- `VINTAGE-WINES`: Asset type identifier (2)
- `LUXURY-COLLECTIBLES`: Asset type identifier (3)

### Error Codes
- `ERR-UNAUTHORIZED (100)`: Insufficient permissions
- `ERR-INSUFFICIENT-BALANCE (101)`: Not enough balance
- `ERR-ASSET-NOT-FOUND (102)`: Asset doesn't exist
- `ERR-INVALID-AMOUNT (103)`: Invalid amount specified
- `ERR-POSITION-NOT-FOUND (104)`: Position doesn't exist
- `ERR-INVALID-PRICE (105)`: Invalid price value

## Getting Started

### Prerequisites
- Stacks wallet with STX tokens
- Access to Stacks blockchain (mainnet/testnet)
- Clarity development environment (optional for development)

### Deployment
1. Deploy the contract to Stacks blockchain
2. Initialize the contract using the `initialize()` function
3. Add initial synthetic assets using `add-asset()`

## Usage Guide

### For Contract Owner (Administrator)

#### Add New Synthetic Asset
```clarity
(contract-call? .rare-assets add-asset "Gold 1oz" u1 u2000000) ;; $2000 per unit
```

#### Update Asset Price
```clarity
(contract-call? .rare-assets update-asset-price u1 u2100000) ;; Update to $2100
```

#### Set Protocol Fee
```clarity
(contract-call? .rare-assets set-protocol-fee u50) ;; 0.5% fee
```

### For Traders

#### Deposit Collateral
```clarity
(contract-call? .rare-assets deposit-collateral u5000000) ;; Deposit 5 STX
```

#### Open Long Position
```clarity
(contract-call? .rare-assets open-long-position u1 u10) ;; Buy 10 units of asset #1
```

#### Close Position
```clarity
(contract-call? .rare-assets close-position u1) ;; Close position #1
```

#### Withdraw Collateral
```clarity
(contract-call? .rare-assets withdraw-collateral u1000000) ;; Withdraw 1 STX
```

## Read-Only Functions

### Check Asset Information
```clarity
(contract-call? .rare-assets get-asset u1)
```

### Check User Balance
```clarity
(contract-call? .rare-assets get-user-balance 'SP1234...)
```

### Check Position Details
```clarity
(contract-call? .rare-assets get-position u1)
```

### Check User Asset Holdings
```clarity
(contract-call? .rare-assets get-user-asset-amount 'SP1234... u1)
```

## Asset Types

| Type ID | Category | Examples |
|---------|----------|----------|
| 1 | Rare Metals | Gold, Silver, Platinum, Palladium |
| 2 | Vintage Wines | Bordeaux, Burgundy, Champagne |
| 3 | Luxury Collectibles | Art, Watches, Classic Cars |

## Fee Structure

- **Protocol Fee**: 0.25% (default, adjustable by owner)
- **Maximum Fee**: 10% (hard-coded limit)
- **Fee Calculation**: Applied on both opening and closing positions

## Trading Flow

1. **Deposit Collateral**: Users deposit STX as collateral
2. **Open Position**: Users buy synthetic exposure to assets
3. **Price Movement**: Asset prices updated by oracle
4. **Close Position**: Users sell positions and realize P&L
5. **Withdraw**: Users can withdraw remaining collateral

## Security Considerations

### Access Control
- Only contract owner can add assets and update prices
- Only position owners can close their positions
- Administrative functions protected by owner checks

### Balance Protection
- All operations verify sufficient balances
- Collateral requirements enforced
- Fee calculations prevent overflow

### Emergency Controls
- Assets can be paused in emergencies
- Owner can reactivate paused assets
- Position closure always available

## Development

### Testing
Run tests using Clarinet:
```bash
clarinet test
```

### Local Development
```bash
clarinet console
```

### Contract Verification
Verify contract deployment:
```bash
clarinet check
```

## API Reference

### Public Functions

| Function | Parameters | Description |
|----------|------------|-------------|
| `initialize()` | - | Initialize contract (owner only) |
| `add-asset()` | name, type, price | Add new synthetic asset |
| `update-asset-price()` | asset-id, price | Update asset price |
| `deposit-collateral()` | amount | Deposit STX collateral |
| `withdraw-collateral()` | amount | Withdraw STX collateral |
| `open-long-position()` | asset-id, amount | Open long position |
| `close-position()` | position-id | Close existing position |
| `set-protocol-fee()` | fee | Set protocol fee (owner only) |
| `pause-asset()` | asset-id | Pause asset trading |
| `reactivate-asset()` | asset-id | Reactivate asset trading |

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## Support

For questions or issues:
- Create an issue on GitHub
- Check the documentation

## Roadmap

- [ ] Multi-collateral support (other SIP-10 tokens)
- [ ] Short positions
- [ ] Automated price feeds
- [ ] Liquidation mechanism
- [ ] Advanced order types
- [ ] Cross-margin trading
- [ ] NFT integration for collectibles

## Disclaimer

This is experimental DeFi software. Users should understand the risks involved in synthetic asset trading. Always do your own research and never invest more than you can afford to lose.