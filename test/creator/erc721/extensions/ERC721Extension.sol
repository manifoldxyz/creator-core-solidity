// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";

interface IERC721Extension {
    function mint(address to) external returns (uint256);

    function mint(address to, string memory uri) external returns (uint256);

    function mintBatch(address to, uint16 count) external returns (uint256[] memory);

    function mintBatch(address to, string[] memory uris) external returns (uint256[] memory);
}

contract ERC721Extension is IERC721Extension {
    address _creator;

    constructor(address creator) {
        _creator = creator;
    }

    function mint(address to) public virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function mint(address to, string memory uri) public virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to, uri);
    }

    function mintBatch(address to, uint16 count) public virtual returns (uint256[] memory) {
        return IERC721CreatorCore(_creator).mintExtensionBatch(to, count);
    }

    function mintBatch(address to, string[] memory uris) public virtual returns (uint256[] memory) {
        return IERC721CreatorCore(_creator).mintExtensionBatch(to, uris);
    }
}
