// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721CreatorCore } from "creator-core/core/IERC721CreatorCore.sol";
import {
    IERC721CreatorExtensionBurnable
} from "creator-core/extensions/ERC721/IERC721CreatorExtensionBurnable.sol";
import {
    IERC165
} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC721Extension } from "./ERC721Extension.sol";

contract ERC721BurnableExtension is
    IERC721CreatorExtensionBurnable,
    ERC721Extension
{
    uint256[] public burntTokens;

    constructor(address creator) ERC721Extension(creator) {}

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0xf3f4e68b || // LEGACY_ERC721_EXTENSION_BURNABLE_INTERFACE
            interfaceId == type(IERC721CreatorExtensionBurnable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function onBurn(address, uint256 tokenId) public {
        burntTokens.push(tokenId);
    }
}
