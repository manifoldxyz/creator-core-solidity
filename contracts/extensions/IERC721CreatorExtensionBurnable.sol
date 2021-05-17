// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorExtensionBase.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC721CreatorExtensionBurnable is ICreatorExtensionBase {
    event CreatorAdded(address indexed creator, address indexed sender);

    /**
     * @dev mint a token
     */
    function mint(address creator, address to) external returns (uint256);

    /**
     * @dev batch mint a token
     */
    function mintBatch(address creator, address to, uint16 count) external returns (uint256[] memory);

    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256 tokenId) external;
}