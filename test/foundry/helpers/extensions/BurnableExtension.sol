// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";
import {ERC721CreatorExtensionBurnable} from "creator-core/extensions/ERC721/ERC721CreatorExtensionBurnable.sol";

struct RoyaltyInfo {
    address payable[] recipients;
    uint256[] values;
}

contract BurnableExtension is ERC721CreatorExtensionBurnable {
    address _creator;
    uint256[] public mintedTokens;
    uint256[] public burntTokens;

    constructor(address creator) {
        _creator = creator;
    }

    function mint(address to) external {
        mintedTokens.push(_mint(_creator, to));
    }

    function mint(address to, string calldata uri) external {
        mintedTokens.push(_mint(_creator, to, uri));
    }

    function mintBatch(address to, uint16 count) external {
        uint256[] memory tokenIds = _mintBatch(_creator, to, count);
        for (uint i; i < tokenIds.length; ) {
            mintedTokens.push(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function mintBatch(address to, string[] calldata uris) external {
        uint256[] memory tokenIds = _mintBatch(_creator, to, uris);
        for (uint i; i < tokenIds.length; ) {
            mintedTokens.push(tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function onBurn(address to, uint256 tokenId) public override {
        ERC721CreatorExtensionBurnable.onBurn(to, tokenId);
        burntTokens.push(tokenId);
    }
}
