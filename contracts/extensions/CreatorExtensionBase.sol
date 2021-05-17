// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";
import "../core/ICreatorCore.sol";
import "./ICreatorExtensionBase.sol";

/**
 * @dev Basic implementation of an extension. Provides an interface to set token uri's
 */
abstract contract CreatorExtensionBase is ERC165, AdminControl, ICreatorExtensionBase {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(ICreatorExtensionBase).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement ICreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri);
    }

    /**
     * @dev See {ICreatorExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri, bool identical) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorExtension-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorExtension-setTokenURI}.
     */
    function setTokenURI(address creator, uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenIds, uris);
    }

}