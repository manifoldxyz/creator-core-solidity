// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "./CreatorCore.sol";

/**
 * @dev Core ERC1155 creator interface
 */
interface IERC1155CreatorCore is ICreatorCore {

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseNew(address to, uint256 amount) external returns (uint256);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseNew(address to, uint256 amount, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatchNew(address to, uint256[] calldata amounts) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Returns tokenId minted
     */
    function mintBaseBatchNew(address to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token with no extension. Can only be called by an admin.
     */
    function mintBaseExisting(address to, uint256 tokenId, uint256 amount) external;

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     */
    function mintBaseBatchExisting(address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionNew(address to, uint256 amount) external returns (uint256);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionNew(address to, uint256 amount, string calldata uri) external returns (uint256);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenIds minted
     */
    function mintExtensionBatchNew(address to, uint256[] calldata amounts) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Returns tokenId minted
     */
    function mintExtensionBatchNew(address to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     */
    function mintExtensionExisting(address to, uint256 tokenId, uint256 amount) external;

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     */
    function mintExtensionBatchExisting(address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(address account, uint256 tokenId, uint256 amount) external;

    /**
     * @dev batch burn tokens. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burnBatch(address account, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

}