// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../extensions/ERC1155/ERC1155CreatorExtensionBurnable.sol";
import "../extensions/CreatorExtensionBasic.sol";

contract MockERC1155CreatorExtensionBurnable is CreatorExtensionBasic, ERC1155CreatorExtensionBurnable {
    uint256 [] _mintedTokens;
    mapping(uint256 => uint256) _burntTokens;
    address _creator;
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(CreatorExtensionBasic, ERC1155CreatorExtensionBurnable) returns (bool) {
        return CreatorExtensionBasic.supportsInterface(interfaceId) || ERC1155CreatorExtensionBurnable.supportsInterface(interfaceId);
    }

    constructor(address creator) {
        _creator = creator;
    }

    function testMintNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external {
        uint256[] memory tokenIds = _mintNew(_creator, to, amounts, uris);
        for (uint i = 0; i < tokenIds.length; i++) {
            _mintedTokens.push(tokenIds[i]);
        }
    }

    function testMintExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        IERC1155CreatorCore(_creator).mintExtensionExisting(to, tokenIds, amounts);
    }

    function mintedTokens() external view returns(uint256[] memory) {
        return _mintedTokens;
    }

    function burntTokens(uint256 tokenId) external view returns(uint256) {
        return _burntTokens[tokenId];
    }

    function onBurn(address to, uint256[] calldata tokenIds, uint256[] calldata amounts) public override {
        ERC1155CreatorExtensionBurnable.onBurn(to, tokenIds, amounts);
        for (uint i = 0; i < tokenIds.length; i++) {
            _burntTokens[tokenIds[i]] += amounts[i];
        }
    }
}
