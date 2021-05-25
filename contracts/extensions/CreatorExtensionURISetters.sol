// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";

import "../core/ICreatorCore.sol";
import "./ICreatorExtensionURISetters.sol";
import "./CreatorExtension.sol";

/**
 * @dev Provides functions to set token uri's
 */
abstract contract CreatorExtensionURISetters is AdminControl, CreatorExtension, ICreatorExtensionURISetters {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionURISetters).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorExtensionURISetters-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement ICreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri);
    }

    /**
     * @dev See {ICreatorExtensionURISetters-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri, bool identical) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorExtensionURISetters-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorExtensionURISetters-setTokenURI}.
     */
    function setTokenURI(address creator, uint256[] calldata tokenIds, string[] calldata uris) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIExtension(tokenIds, uris);
    }

    /**
     * @dev See {ICreatorExtensionURISetters-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(address creator, string calldata prefix) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId), "CreatorExtension: Requires creator to implement CreatorCore");
        ICreatorCore(creator).setTokenURIPrefixExtension(prefix);
    }


}