// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";
import "./IERC721CreatorExtensionMulti.sol";
import "./ERC721CreatorExtension.sol";

abstract contract ERC721CreatorExtensionMulti is ERC721CreatorExtension, IERC721CreatorExtensionMulti {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal _creators;

    constructor(address[] memory creators) {
        for (uint i = 0; i < creators.length; i++) {
            address creator = creators[i];
            require(ERC165Checker.supportsInterface(creator, type(IERC721Creator).interfaceId), "ERC721CreatorExtensionMulti: Must implement IERC721Creator");
            _creators.add(creator);
            emit CreatorAdded(creator, msg.sender);
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorExtension, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionMulti).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorExtensionMulti-addERC721Creator}.
     */
    function addERC721Creator(address creator) external override adminRequired {
        require(ERC165Checker.supportsInterface(creator, type(IERC721Creator).interfaceId), "ERC721CreatorExtensionMulti: Must implement IERC721Creator");
        if (!_creators.contains(creator)) {
            _creators.add(creator);
            emit CreatorAdded(creator, msg.sender);
        }
    }

    /**
     * @dev See {IERC721CreatorExtension-onBurn}.
     */
    function onBurn(address, uint256) public virtual override(ERC721CreatorExtension, IERC721CreatorExtension) {
        require(!_creators.contains(msg.sender), "ERC721CreatorExtensionMulti: Can only be called by token creator");
    }


}