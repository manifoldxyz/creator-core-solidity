// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/IERC165.sol";
import "./access/IAdminControl.sol";

/**
 * @dev Required interface of an ERC721Creator compliant extension contracts.
 */
interface IERC721CreatorExtension is IERC165, IAdminControl {

    /**
     * @dev callback handler for burn events
     */
    function onBurn(uint256 tokenId) external returns (bool);
}