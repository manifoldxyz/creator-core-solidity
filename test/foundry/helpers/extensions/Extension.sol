// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721CreatorCore } from "creator-core/core/IERC721CreatorCore.sol";

interface IExtension {
    function mint(address to) external returns (uint256);

    function mint(address to, string calldata uri) external returns (uint256);

    function mintBatch(
        address to,
        uint16 count
    ) external returns (uint256[] memory);

    function mintBatch(
        address to,
        string[] calldata uris
    ) external returns (uint256[] memory);
}

contract Extension is IExtension {
    address _creator;

    constructor(address creator) {
        _creator = creator;
    }

    function mint(address to) public virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to);
    }

    function mint(
        address to,
        string calldata uri
    ) public virtual returns (uint256) {
        return IERC721CreatorCore(_creator).mintExtension(to, uri);
    }

    function mintBatch(
        address to,
        uint16 count
    ) public virtual returns (uint256[] memory) {
        return IERC721CreatorCore(_creator).mintExtensionBatch(to, count);
    }

    function mintBatch(
        address to,
        string[] calldata uris
    ) public virtual returns (uint256[] memory) {
        return IERC721CreatorCore(_creator).mintExtensionBatch(to, uris);
    }
}
