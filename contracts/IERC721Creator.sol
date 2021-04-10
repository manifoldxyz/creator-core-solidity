// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IERC721Creator is IERC721Enumerable {

    /**
     * @dev gets address of all admins
     */
    function getAdmins() external view returns (address[] memory);

    /**
     * @dev add an admin.  Can only be called by contract owner.
     * Returns True if newly added, False if already added.
     */
    function approveAdmin(address admin) external returns (bool);

    /**
     * @dev remove an admin.  Can only be called by contract owner.
     * Returns True if removed, False if already removed.
     */
    function revokeAdmin(address admin) external returns (bool);

    /**
     * @dev gets address of all extensions
     */
    function getExtensions() external view returns (address[] memory);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * extension address must point to a contract implementing IERC721CreatorExtension.
     * Returns True if newly added, False if already added.
     */
    function registerExtension(address extension) external returns (bool);

    /**
     * @dev add an extension.  Can only be called by contract owner or admin.
     * Returns True if removed, False if already removed.
     */
    function unregisterExtension(address extension) external returns (bool);

    /**
     * @dev mint a token. Can only be called by a registered extension.
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * @dev burn a token. Can only be called by token owner or approved address.
     * On burn, calls back to the registered extension's onBurn method
     */
    function burn(uint256 tokenId) external;

}
