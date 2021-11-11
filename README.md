# manifoldxyz-creator-core-solidity

## The Manifold Creator Core Contracts

**A library for extendible creator contracts.**

 * Implementation for ERC721
 * Implementation for ERC1155

The Manifold Creator Core contracts provide creators with the ability to deploy an ERC721/ERC1155 NFT smart contract with basic minting functionality, on-chain royalties and permissioning.  Additionally, they provide a framework for extending the functionality of the smart contract by installing extension applications.

These contracts are used in the [Manifold Studio](https://studio.manifoldxyz.dev/).

This enables creators to use the same underlying Manifold Creator Core contract to continue creating new and innovative NFT's and experiences.

See our [blog post on the Manifold Creator Core](https://manifoldxyz.substack.com/p/manifold-creator) for more information.

Visit our [blog](https://manifoldxyz.substack.com/) for example applications that have been added to Manifold Creator Core contracts.

## Overview

### Installation

```console
$ npm install @manifoldxyz/creator-core-solidity
```

### Usage

Once installed, you can use the contracts in the library by importing them:

```solidity
pragma solidity ^0.8.0;

import "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract MyContract is ERC721Creator  {
    constructor() ERC721Creator ("MyContract", "MC") {
    }
}
```

The available contracts are:

 * ERC721Creator
 * ERC721CreatorUpgradeable - A transparent proxy upgradeable version of ERC721Creator
 * ERC721CreatorEnumerable - Note that using enumerable significantly increase mint costs by around 2x
 * ERC1155Creator

[Manifold Studio](https://studio.manifoldxyz.dev/) currently makes use of ERC721Creator and ERC1155Creator

## Learn More

## Running the package unit tests

Visit the [github repo](https://github.com/manifoldxyz/creator-core-solidity) and clone the repo.  It uses the truffle framework and ganache-cli.

Install both:
```
npm install -g truffle
npm install -g ganache-cli
```

### install dependencies
npm install

### Compile
truffle compile

### Start development server
ganache-cli

### Deploy migrations
truffle migrate

### Run tests
truffle test

