// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721CreatorCore.sol";
import "./IERC721CreatorCoreEnumerable.sol";

abstract contract ERC721CreatorCoreEnumerable is ERC721CreatorCore, IERC721CreatorCoreEnumerable {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    // For enumerating tokens for a given extension
    mapping (address => uint256) private _extensionBalances;
    mapping (address => mapping(uint256 => uint256)) private _extensionTokens;
    mapping (uint256 => uint256) private _extensionTokensIndex;

    // For enumerating an extension's tokens for an owner
    mapping (address => mapping(address => uint256)) private _extensionBalancesByOwner;
    mapping (address => mapping(address => mapping(uint256 => uint256))) private _extensionTokensByOwner;
    mapping (uint256 => uint256) private _extensionTokensIndexByOwner;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorCore, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorCoreEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }


    /**
     * @dev See {IERC721CreatorCoreEnumerable-totalSupplyExtension}.
     */
    function totalSupplyExtension(address extension) public view virtual override nonBlacklistRequired(extension) returns (uint256) {
        return _extensionBalances[extension];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-tokenByIndexExtension}.
     */
    function tokenByIndexExtension(address extension, uint256 index) external view virtual override nonBlacklistRequired(extension) returns (uint256) {
        require(index < totalSupplyExtension(extension), "ERC721Creator: Index out of bounds");
        return _extensionTokens[extension][index];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-balanceOfExtension}.
     */
    function balanceOfExtension(address extension, address owner) public view virtual override nonBlacklistRequired(extension) returns (uint256) {
        return _extensionBalancesByOwner[extension][owner];
    }

    /*
     * @dev See {IERC721CeratorCoreEnumerable-tokenOfOwnerByIndexExtension}.
     */
    function tokenOfOwnerByIndexExtension(address extension, address owner, uint256 index) external view virtual override nonBlacklistRequired(extension) returns (uint256) {
        require(index < balanceOfExtension(extension, owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[extension][owner][index];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-totalSupplyBase}.
     */
    function totalSupplyBase() public view virtual override returns (uint256) {
        return _extensionBalances[address(this)];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-tokenByIndexBase}.
     */
    function tokenByIndexBase(uint256 index) external view virtual override returns (uint256) {
        require(index < totalSupplyBase(), "ERC721Creator: Index out of bounds");
        return _extensionTokens[address(this)][index];
    }

    /**
     * @dev See {IERC721CreatorCoreEnumerable-balanceOfBase}.
     */
    function balanceOfBase(address owner) public view virtual override returns (uint256) {
        return _extensionBalancesByOwner[address(this)][owner];
    }

    /*
     * @dev See {IERC721CeratorCoreEnumerable-tokenOfOwnerByIndeBase}.
     */
    function tokenOfOwnerByIndexBase(address owner, uint256 index) external view virtual override returns (uint256) {
        require(index < balanceOfBase(owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[address(this)][owner][index];
    }


    function _postMintBase(address to, uint256 tokenId) internal virtual override {
        // Add to extension token tracking
        uint256 length = totalSupplyBase();
        _extensionTokens[address(this)][length] = tokenId;
        _extensionTokensIndex[tokenId] = length;
        _extensionBalances[address(this)] += 1;

        // Add to extension token tracking by owner
        uint256 lengthByOwner = balanceOfBase(to);
        _extensionTokensByOwner[address(this)][to][lengthByOwner] = tokenId;
        _extensionTokensIndexByOwner[tokenId] = lengthByOwner;
        _extensionBalancesByOwner[address(this)][to] += 1;
    }

    function _postMintExtension(address to, uint256 tokenId) internal virtual override {
        // Add to extension token tracking
        uint256 length = totalSupplyExtension(msg.sender);
        _extensionTokens[msg.sender][length] = tokenId;
        _extensionTokensIndex[tokenId] = length;
        _extensionBalances[msg.sender] += 1;

        // Add to extension token tracking by owner
        uint256 lengthByOwner = balanceOfExtension(msg.sender, to);
        _extensionTokensByOwner[msg.sender][to][lengthByOwner] = tokenId;
        _extensionTokensIndexByOwner[tokenId] = lengthByOwner;
        _extensionBalancesByOwner[msg.sender][to] += 1;        
    }
    
    function _preBurn(address owner, uint256 tokenId) internal override(ERC721CreatorCore) virtual {
        address tokenExtension_ = _tokensExtension[tokenId];

        /*************************************************
         *  START: Remove from extension token tracking
         *************************************************/

        uint256 lastTokenIndex = totalSupplyExtension(tokenExtension_) - 1;
        uint256 tokenIndex = _extensionTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _extensionTokens[tokenExtension_][lastTokenIndex];

            _extensionTokens[tokenExtension_][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _extensionTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _extensionBalances[tokenExtension_] -= 1;

        // This also deletes the contents at the last position of the array
        delete _extensionTokensIndex[tokenId];
        delete _extensionTokens[tokenExtension_][lastTokenIndex];

        /*************************************************
         * END
         *************************************************/


        /********************************************************
         *  START: Remove from extension token tracking by owner
         ********************************************************/

        uint256 lastTokenIndexByOwner = balanceOfExtension(tokenExtension_, owner) - 1;
        uint256 tokenIndexByOwner = _extensionTokensIndexByOwner[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndexByOwner != lastTokenIndexByOwner) {
            uint256 lastTokenIdByOwner = _extensionTokensByOwner[tokenExtension_][owner][lastTokenIndexByOwner];

            _extensionTokensByOwner[tokenExtension_][owner][tokenIndexByOwner] = lastTokenIdByOwner; // Move the last token to the slot of the to-delete token
            _extensionTokensIndexByOwner[lastTokenIdByOwner] = tokenIndexByOwner; // Update the moved token's index
        }
        _extensionBalancesByOwner[tokenExtension_][owner] -= 1;

        // This also deletes the contents at the last position of the array
        delete _extensionTokensIndexByOwner[tokenId];
        delete _extensionTokensByOwner[tokenExtension_][owner][lastTokenIndexByOwner];

        /********************************************************
         *  END
         ********************************************************/
         
         ERC721CreatorCore._preBurn(owner, tokenId);
    }

}