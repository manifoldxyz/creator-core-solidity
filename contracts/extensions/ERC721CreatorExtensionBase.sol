// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";
import "../IERC721Creator.sol";
import "./IERC721CreatorExtensionBase.sol";

abstract contract ERC721CreatorExtensionBase is ERC165, AdminControl, IERC721CreatorExtensionBase {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionBase).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri) external override adminRequired {
        IERC721Creator(creator).setBaseTokenURIExtension(uri);
    }

    /**
     * @dev See {IERC721CreatorExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri, bool identical) external override adminRequired {
        IERC721Creator(creator).setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {IERC721CreatorExtension-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external override adminRequired {
        IERC721Creator(creator).setTokenURIExtension(tokenId, uri);
    }

}