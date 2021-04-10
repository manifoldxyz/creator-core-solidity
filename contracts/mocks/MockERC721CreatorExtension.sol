// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721CreatorExtension.sol";
import "../IERC721Creator.sol";

contract MockERC721CreatorExtension is ERC721CreatorExtension {
    
    constructor(address creator_) ERC721CreatorExtension (creator_) {
    }

    function testMint(address to) external returns (uint256) {
        return IERC721Creator(_creator).mint(to);
    }

    function onBurn(uint256 tokenId) external pure override returns (bool) {
        return tokenId >= 0;
    }
}
