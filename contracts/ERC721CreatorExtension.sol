// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";
import "./IERC721Creator.sol";
import "./IERC721CreatorExtension.sol";
import "./access/AdminControl.sol";

abstract contract ERC721CreatorExtension is ERC165, AdminControl, IERC721CreatorExtension {
     address internal immutable _creator;

     constructor(address creator_) {
         require(ERC165Checker.supportsInterface(creator_, type(IERC721Creator).interfaceId), "ERC721CreatorExtension: Must implement IERC721Creator");
         _creator = creator_;
     }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721CreatorExtension).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtension-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        IERC721Creator(_creator).setBaseTokenURI(uri);
    }

    /**
     * @dev See {IERC721Creator-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        IERC721Creator(_creator).setTokenURI(tokenId, uri);
    }
}