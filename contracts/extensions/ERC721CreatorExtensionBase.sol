// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";
import "../IERC721CreatorCore.sol";
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
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtension: Requires ERC721CreatorCore");
        IERC721CreatorCore(creator).setBaseTokenURIExtension(uri);
    }

    /**
     * @dev See {IERC721CreatorExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri, bool identical) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtension: Requires ERC721CreatorCore");
        IERC721CreatorCore(creator).setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {IERC721CreatorExtension-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtension: Requires ERC721CreatorCore");
        IERC721CreatorCore(creator).setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {IERC721CreatorExtension-setTokenURI}.
     */
    function setTokenURI(address creator, uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721CreatorCore).interfaceId), "ERC721CreatorExtension: Requires ERC721CreatorCore");
        IERC721CreatorCore(creator).setTokenURIExtension(tokenIds, uris);
    }

}