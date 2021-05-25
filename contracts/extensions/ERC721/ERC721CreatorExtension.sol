// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../CreatorExtension.sol";

/**
 * @dev Base ERC721 creator extension variables
 */
abstract contract ERC721CreatorExtension is CreatorExtension {

    bytes4 constant internal LEGACY_EXTENSION_BURNABLE_INTERFACE = 0xf3f4e68b;

}