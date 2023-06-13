<div align="center">
  <h1 align="center">mint-from-ethereum</h1>
  <p align="center">
    <a href="https://discord.gg/qqkBpmRDFE">
        <img src="https://img.shields.io/badge/Discord-6666FF?style=for-the-badge&logo=discord&logoColor=white">
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=Carbonable_io">
        <img src="https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white">
    </a>       
  </p>
  <h3 align="center">Carbonable L1 Project Minter</h3>
</div>

### Description

This repository contains the Solidity code that enables bridged-minting Carbonable projects from Ethereum.
To mint on L1, the users pays a smart contract on Ethereum that checks the amounts and project status.
A L2 message is sent to the Starknet contract which mints the asset.

### Project setup

#### 📦 Requirements

- [foundry](https://book.getfoundry.sh/)

### ⛏️ Compile

```bash
forge build
```

### 🌡️ Test

```bash
forge test
```

## 📄 License

This project is released under the Apache 2 license.
