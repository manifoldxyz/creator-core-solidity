// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";
import {IERC165} from "openzeppelin/utils/introspection/ERC165.sol";
import {AdminControl} from "manifoldxyz/libraries-solidity/access/AdminControl.sol";
import {ICreatorCore} from "../core/ICreatorCore.sol";
import {ICreatorExtensionBasic} from "./ICreatorExtensionBasic.sol";
import {CreatorExtension} from "./CreatorExtension.sol";

/**
 * @dev Provides functions to set token uri's
 */
abstract contract CreatorExtensionBasic is AdminControl, CreatorExtension, ICreatorExtensionBasic {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AdminControl, CreatorExtension, IERC165)
        returns (bool)
    {
        return interfaceId == type(ICreatorExtensionBasic).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri) external override adminRequired {
        require(
            ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId),
            "Requires creator to implement ICreatorCore"
        );
        ICreatorCore(creator).setBaseTokenURIExtension(uri);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setBaseTokenURI}.
     */
    function setBaseTokenURI(address creator, string calldata uri, bool identical) external override adminRequired {
        require(
            ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId),
            "Requires creator to implement CreatorCore"
        );
        ICreatorCore(creator).setBaseTokenURIExtension(uri, identical);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURI}.
     */
    function setTokenURI(address creator, uint256 tokenId, string calldata uri) external override adminRequired {
        require(
            ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId),
            "Requires creator to implement CreatorCore"
        );
        ICreatorCore(creator).setTokenURIExtension(tokenId, uri);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURI}.
     */
    function setTokenURI(address creator, uint256[] calldata tokenIds, string[] calldata uris)
        external
        override
        adminRequired
    {
        require(
            ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId),
            "Requires creator to implement CreatorCore"
        );
        ICreatorCore(creator).setTokenURIExtension(tokenIds, uris);
    }

    /**
     * @dev See {ICreatorExtensionBasic-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(address creator, string calldata prefix) external override adminRequired {
        require(
            ERC165Checker.supportsInterface(creator, type(ICreatorCore).interfaceId),
            "Requires creator to implement CreatorCore"
        );
        ICreatorCore(creator).setTokenURIPrefixExtension(prefix);
    }
}
