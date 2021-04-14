// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz


import "../../../features/nft2erc20/NFT2ERC20.sol";

contract ASH is NFT2ERC20 {

    constructor() NFT2ERC20("Burn", "ASH") {}

}