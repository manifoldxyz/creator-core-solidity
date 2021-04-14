// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../features/nft2erc20/NFT2ERC20RateEngine.sol";

contract MockNFT2ERC20RateEngine is NFT2ERC20RateEngine {
     constructor() {}

     function getRate(uint256, address, uint256[] calldata, string calldata) external pure override returns (uint256) {
         return 10;
     }
}