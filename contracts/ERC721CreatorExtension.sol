// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";
import "solidity-libraries/contracts/access/AdminControl.sol";
import "./IERC721Creator.sol";
import "./IERC721CreatorExtension.sol";

abstract contract ERC721CreatorExtension is ERC165, AdminControl, IERC721CreatorExtension {
     address internal immutable _creator;

     constructor(address creator) {
         require(ERC165Checker.supportsInterface(creator, type(IERC721Creator).interfaceId), "ERC721CreatorExtension: Must implement IERC721Creator");
         _creator = creator;
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
     * @dev See {IERC721CreatorExtension-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        IERC721Creator(_creator).setTokenURI(tokenId, uri);
    }

    /**
     * @dev See {IERC721CreatorExtension-onBurn}.
     */
    function onBurn(address, uint256) public virtual override {
        require(msg.sender == _creator, "ERC721CreatorExtension: Can only be called by token creator");
    }
}