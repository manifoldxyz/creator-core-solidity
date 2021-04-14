// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an INFT2ERC20 compliant converter contracts.
 */
interface INFT2ERC20RateEngine is IERC165 {
    /*
     * @dev get the conversion rate for a given NFT
     */
    function getRate(uint256 totalSupply, address tokenContract, uint256[] calldata args, string calldata spec) external view returns (uint256);

}