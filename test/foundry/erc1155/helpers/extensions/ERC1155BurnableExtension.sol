// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155CreatorCore } from "creator-core/core/IERC1155CreatorCore.sol";
import {
    IERC1155CreatorExtensionBurnable
} from "creator-core/extensions/ERC1155/IERC1155CreatorExtensionBurnable.sol";
import {
    IERC165
} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ERC1155Extension } from "./ERC1155Extension.sol";

contract ERC1155BurnableExtension is
    IERC1155CreatorExtensionBurnable,
    ERC1155Extension
{
    mapping(uint256 => uint256) public burntTokens;

    constructor(address creator) ERC1155Extension(creator) {}

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == 0xf3f4e68b || // LEGACY_ERC1155_EXTENSION_BURNABLE_INTERFACE
            interfaceId == type(IERC1155CreatorExtensionBurnable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function onBurn(
        address,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public override {
        for (uint i; i < tokenIds.length; ) {
            burntTokens[tokenIds[i]] += amounts[i];
            unchecked {
                ++i;
            }
        }
    }
}
