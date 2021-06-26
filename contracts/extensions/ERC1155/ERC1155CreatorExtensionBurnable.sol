// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

import "../../core/IERC1155CreatorCore.sol";
import "./IERC1155CreatorExtensionBurnable.sol";

/**
 * @dev Suggested implementation for extensions that want to receive onBurn callbacks
 * Mint tracks the creators/tokens created, and onBurn only accepts callbacks from
 * the creator of a token created.
 */
abstract contract ERC1155CreatorExtensionBurnable is AdminControl, IERC1155CreatorExtensionBurnable {

    mapping (uint256 => address) private _tokenCreators;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AdminControl, IERC165) returns (bool) {
        return interfaceId == type(IERC1155CreatorExtensionBurnable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev batch mint a token
     */
    function mintNew(address creator, address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external adminRequired returns (uint256[] memory) {
        return _mintNew(creator, to, amounts, uris);
    }

    function _mintNew(address creator, address[] calldata to, uint256[] calldata amounts, string[] calldata uris) internal returns (uint256[] memory tokenIds) {
        require(ERC165Checker.supportsInterface(creator, type(IERC1155CreatorCore).interfaceId), "creator must implement IERC1155CreatorCore");
        tokenIds = IERC1155CreatorCore(creator).mintExtensionNew(to, amounts, uris);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenCreators[tokenIds[i]] = creator;
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC1155CreatorExtension-onBurn}.
     */
    function onBurn(address, uint256[] calldata tokenIds, uint256[] calldata) public virtual override {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokenCreators[tokenIds[i]] == msg.sender, "Can only be called by token creator");
        }
    }


}