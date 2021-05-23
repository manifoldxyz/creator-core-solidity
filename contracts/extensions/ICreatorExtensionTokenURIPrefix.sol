// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "manifoldxyz-libraries-solidity/contracts/access/IAdminControl.sol";

/**
 * @dev Implement this to be able to set the extension's token uri prefix
 */
interface ICreatorExtensionTokenURIPrefix is IERC165, IAdminControl {

    /**
     * @dev set the extension's token uri prefix
     */
    function setTokenURIPrefix(address creator, string calldata prefix) external;
}
