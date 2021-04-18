// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721CreatorExtension.sol";
import "../IERC721Creator.sol";

contract MockERC721CreatorExtension is ERC721CreatorExtension {
    uint256 [] _mintedTokens;
    uint256 [] _burntTokens;
    
    constructor(address creator_) ERC721CreatorExtension (creator_) {
    }

    function testMint(address to) external {
        _mintedTokens.push(IERC721Creator(_creator).mint(to));
    }

    function mintedTokens() external view returns(uint256[] memory) {
        return _mintedTokens;
    }

    function burntTokens() external view returns(uint256[] memory) {
        return _burntTokens;
    }

    function onBurn(address to, uint256 tokenId) public override {
        ERC721CreatorExtension.onBurn(to, tokenId);
        _burntTokens.push(tokenId);
    }
}
