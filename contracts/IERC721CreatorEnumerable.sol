// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IERC721Creator.sol";

interface IERC721CreatorEnumerable is IERC721Creator, IERC721Enumerable {

    /*
     * @dev gets the total number of tokens created by the extension (unburned)
     */
    function totalSupplyExtension(address extension) external view returns (uint256);

    /*
     * @dev gets tokenId of an extension by index. 
     * Iterate over this to get the full list of tokens of a given extension
     */
    function tokenByIndexExtension(address extension, uint256 index) external view returns (uint256);

    /*
     * @dev get balance of owner for an extension
     */
   function balanceOfExtension(address extension, address owner) external view returns (uint256 balance);

   /*
    * @dev Returns a token ID owned by `owner` at a given `index` of its token list for a given extension
    */
   function tokenOfOwnerByIndexExtension(address extension, address owner, uint256 index) external view returns (uint256 tokenId);

    /*
     * @dev gets the total number of tokens created with no extension
     */
    function totalSupplyNoExtension() external view returns (uint256);

    /*
     * @dev gets tokenId of the root creator contract by index. 
     * Iterate over this to get the full list of tokens with no extension.
     */
    function tokenByIndexNoExtension(uint256 index) external view returns (uint256);

    /*
     * @dev get balance of owner for tokens with no extension
     */
    function balanceOfNoExtension(address owner) external view returns (uint256 balance);

    /*
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list for tokens with no extension
     */
    function tokenOfOwnerByIndexNoExtension(address owner, uint256 index) external view returns (uint256 tokenId);

}
