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
     * Use an empty uris array if you want to use the default uri for all tokens.
     * Use an empty uri string if you want to use the default uri for one token.
     * Passing an array of 'to' receivers will result in generating a single new token.  Requires 0 (use default) or 1 uri.
     *     If you pass in a single amount, every receiver will get the same amount.  If you pass in an array, it must be equal in length
     *     to the receiver array and each receiver will get the corresponding amount of the new token.
     * Returns tokenId minted
     */
    function mintBaseNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint a token with no extension. Can only be called by an admin.
     * Passing in a single element 'to' with an array of tokenIds and amounts will cause all tokens to go to the same address
     * Passing in a single element 'tokenids' with an array of to and amounts will cause all recipients to get the same token
     * Passing in a single element 'tokenids' and 'amounts' will cause the same amount of tokens to go to all recipients
     */
    function mintBaseExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Use an empty uris array if you want to use the default uri for all tokens.
     * Use an empty uri string if you want to use the default uri for one token.
     * Passing an array of 'to' receivers will result in generating a single new token.  Requires 0 (use default) or 1 uri.
     *     If you pass in a single amount, every receiver will get the same amount.  If you pass in an array, it must be equal in length
     *     to the receiver array and each receiver will get the corresponding amount of the new token.
     * Returns tokenId minted
     */
    function mintExtensionNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external returns (uint256[] memory);

    /**
     * @dev batch mint a token. Can only be called by a registered extension.
     * Passing in a single element 'to' with an array of tokenIds and amounts will cause all tokens to go to the same address
     * Passing in a single element 'tokenids' with an array of to and amounts will cause all recipients to get the same token
     * Passing in a single element 'tokenids' and 'amounts' will cause the same amount of tokens to go to all recipients
     */
    function mintExtensionExisting(address[] calldata to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

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