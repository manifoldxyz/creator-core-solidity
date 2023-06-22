// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";
import {IERC721CreatorExtensionBurnable} from "creator-core/extensions/ERC721/IERC721CreatorExtensionBurnable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Extension} from "./Extension.sol";

contract BurnableExtension is IERC721CreatorExtensionBurnable, Extension {
    uint256[] public mintedTokens;
    uint256[] public burntTokens;

    constructor(address creator) Extension(creator) {}

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0xf3f4e68b || // LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE
            interfaceId == type(IERC721CreatorExtensionBurnable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function mint(address to) public override returns (uint256) {
        uint256 tokenId = super.mint(to);
        mintedTokens.push(tokenId);
        return tokenId;
    }

    function mint(
        address to,
        string calldata uri
    ) public override returns (uint256) {
        uint256 tokenId = super.mint(to, uri);
        mintedTokens.push(tokenId);
        return tokenId;
    }

    function mintBatch(
        address to,
        uint16 count
    ) public override returns (uint256[] memory) {
        uint256[] memory tokenIds = super.mintBatch(to, count);
        for (uint i; i < tokenIds.length; ) {
            mintedTokens.push(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    function mintBatch(
        address to,
        string[] calldata uris
    ) public override returns (uint256[] memory) {
        uint256[] memory tokenIds = super.mintBatch(to, uris);
        for (uint i; i < tokenIds.length; ) {
            mintedTokens.push(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    function onBurn(address, uint256 tokenId) public {
        burntTokens.push(tokenId);
    }
}
