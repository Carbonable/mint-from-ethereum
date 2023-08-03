# Carbonable L2 Ethereum Minter

### Description

Starknet Contract handling mints from L1.
To mint on L1, the users pays a smart contract on Ethereum that checks the amounts and project status.
A L2 message is sent to the Starknet contract which mints the asset.

### 📦 Requirements

- [asdf-scarb](https://github.com/software-mansion/asdf-scarb)

### ⛏️ Compile

```bash
scarb build
```

## 🌡️ Test

```bash
scarb test
```
