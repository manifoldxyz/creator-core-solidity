// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../extensions/ERC721/ERC721CreatorExtensionBurnable.sol";
import "../extensions/CreatorExtensionBasic.sol";

contract MockERC721CreatorExtensionBurnable is CreatorExtensionBasic, ERC721CreatorExtensionBurnable {
    uint256 [] _mintedTokens;
    uint256 [] _burntTokens;
    address _creator;
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtensionBasic, ERC721CreatorExtensionBurnable) returns (bool) {
        return CreatorExtensionBasic.supportsInterface(interfaceId) || ERC721CreatorExtensionBurnable.supportsInterface(interfaceId);
    }

    constructor(address creator) {
        _creator = creator;
    }

    function testMint(address to) external {
        _mintedTokens.push(_mint(_creator, to));
    }

    function testMint(address to, string calldata uri) external {
        _mintedTokens.push(_mint(_creator, to, uri));
    }

    function testMintBatch(address to, uint16 count) external {
        uint256[] memory tokenIds = _mintBatch(_creator, to, count);
        for (uint i = 0; i < tokenIds.length; i++) {
            _mintedTokens.push(tokenIds[i]);
        }
    }

    function testMintBatch(address to, string[] calldata uris) external {
        uint256[] memory tokenIds = _mintBatch(_creator, to, uris);
        for (uint i = 0; i < tokenIds.length; i++) {
            _mintedTokens.push(tokenIds[i]);
        }
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
