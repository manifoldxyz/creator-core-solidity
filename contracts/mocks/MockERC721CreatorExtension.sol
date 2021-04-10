// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Creator.sol";
import "../ERC721CreatorExtension.sol";

contract MockERC721CreatorExtension is ERC721CreatorExtension {
    
    uint256 tokenCounter = 0;

    constructor(address creator_) ERC721CreatorExtension (creator_) {
    }

    function testMint(address to) external {
        ERC721Creator(_creator).mint(to, tokenCounter);
        tokenCounter++;
    }

    function onBurn(uint256 tokenId) external pure override returns (bool) {
        return tokenId >= 0;
    }
}
