// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./ICreatorExtensionBase.sol";

/**
 * @dev Your extension is required to implement this interface if it wishes
 * to receive the onBurn callback whenever a token the extension created is
 * burned
 */
interface IERC1155CreatorExtensionBurnable is ICreatorExtensionBase {
    event CreatorAdded(address indexed creator, address indexed sender);

    /**
     * @dev mint a token
     */
    function mintNew(address creator, address to, uint256 amount) external returns (uint256);

    /**
     * @dev batch mint a token
     */
    function mintBatchNew(address creator, address to, uint256[] calldata amounts) external returns (uint256[] memory);

    /**
     * @dev mint a token
     */
    function mintExisting(address creator, address to, uint256 tokenId, uint256 amount) external;

    /**
     * @dev batch mint a token
     */
    function mintBatchExisting(address creator, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev callback handler for burn events
     */
    function onBurn(address owner, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
}