// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../extensions/ERC721CreatorExtensionBurnable.sol";

contract MockERC721CreatorExtension is ERC721CreatorExtensionBurnable {
    uint256 [] _mintedTokens;
    uint256 [] _burntTokens;
    address _creator;
    
    constructor(address creator) {
        _creator = creator;
    }

    function testMint(address to) external {
        _mintedTokens.push(_mint(_creator, to));
    }

    function mintedTokens() external view returns(uint256[] memory) {
        return _mintedTokens;
    }

    function burntTokens() external view returns(uint256[] memory) {
        return _burntTokens;
    }

    function onBurn(address to, uint256 tokenId) public override {
        ERC721CreatorExtensionBurnable.onBurn(to, tokenId);
        _burntTokens.push(tokenId);
    }
}
