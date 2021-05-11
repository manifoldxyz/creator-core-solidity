// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC721Creator.sol";
import "./IERC721CreatorEnumerable.sol";

contract ERC721CreatorEnumerable is ERC721Creator, ERC721Enumerable, IERC721CreatorEnumerable {
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

    constructor (string memory _name, string memory _symbol) ERC721Creator(_name, _symbol) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Creator, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721CreatorEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721CreatorEnumerable-totalSupplyExtension}.
     */
    function totalSupplyExtension(address extension) public view virtual override nonBlacklistRequired(extension) returns (uint256) {
        return _extensionBalances[extension];
    }

    /**
     * @dev See {ERC721Enumerable-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721CreatorEnumerable-tokenByIndexExtension}.
     */
    function tokenByIndexExtension(address extension, uint256 index) external view virtual override nonBlacklistRequired(extension) returns (uint256) {
        require(index < totalSupplyExtension(extension), "ERC721Creator: Index out of bounds");
        return _extensionTokens[extension][index];
    }

    /**
     * @dev See {IERC721CreatorEnumerable-balanceOfExtension}.
     */
    function balanceOfExtension(address extension, address owner) public view virtual override nonBlacklistRequired(extension) returns (uint256) {
        return _extensionBalancesByOwner[extension][owner];
    }

    /*
     * @dev See {IERC721CeratorEnumerable-tokenOfOwnerByIndexExtension}.
     */
    function tokenOfOwnerByIndexExtension(address extension, address owner, uint256 index) external view virtual override nonBlacklistRequired(extension) returns (uint256) {
        require(index < balanceOfExtension(extension, owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[extension][owner][index];
    }

    /**
     * @dev See {IERC721CreatorEnumerable-totalSupplyBase}.
     */
    function totalSupplyBase() public view virtual override returns (uint256) {
        return _extensionBalances[address(this)];
    }

    /**
     * @dev See {IERC721CreatorEnumerable-tokenByIndexBase}.
     */
    function tokenByIndexBase(uint256 index) external view virtual override returns (uint256) {
        require(index < totalSupplyBase(), "ERC721Creator: Index out of bounds");
        return _extensionTokens[address(this)][index];
    }

    /**
     * @dev See {IERC721CreatorEnumerable-balanceOfBase}.
     */
    function balanceOfBase(address owner) public view virtual override returns (uint256) {
        return _extensionBalancesByOwner[address(this)][owner];
    }

    /*
     * @dev See {IERC721CeratorEnumerable-tokenOfOwnerByIndeBase}.
     */
    function tokenOfOwnerByIndexBase(address owner, uint256 index) external view virtual override returns (uint256) {
        require(index < balanceOfBase(owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[address(this)][owner][index];
    }

    /**
     * @dev See {IERC721Creator-mintBase}.
     */
    function mintBase(address to) public override(ERC721Creator, IERC721Creator) nonReentrant adminRequired virtual returns(uint256) {
        return _mintBase(to, "");
    }

    /**
     * @dev See {IERC721Creator-mintBase}.
     */
    function mintBase(address to, string calldata uri) public override(ERC721Creator, IERC721Creator) nonReentrant adminRequired virtual returns(uint256) {
        return _mintBase(to, uri);
    }

    function _mintBase(address to, string memory uri) internal override(ERC721Creator) virtual returns(uint256 tokenId) {
        tokenId = ERC721Creator._mintBase(to, uri);

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

        return tokenId;
    }

    /**
     * @dev See {IERC721Creator-extensionMint}.
     */
    function mintExtension(address to) public override(ERC721Creator, IERC721Creator) nonReentrant extensionRequired virtual returns(uint256) {
        return _mintExtension(to, "");
    }

    /**
     * @dev See {IERC721Creator-extensionMint}.
     */
    function mintExtension(address to, string calldata uri) public override(ERC721Creator, IERC721Creator) nonReentrant extensionRequired virtual returns(uint256) {
        return _mintExtension(to, uri);
    }

    function _mintExtension(address to, string memory uri) internal override(ERC721Creator) virtual returns(uint256 tokenId) {
        tokenId = ERC721Creator._mintExtension(to, uri);

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

        return tokenId;
    }
    
    /**
     * @dev See {IERC721Creator-burn}.
     */
    function burn(uint256 tokenId) public override(ERC721Creator, IERC721Creator) nonReentrant virtual {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721Creator, ERC721) virtual {
        address tokenExtension_ = _tokenExtension[tokenId];
        address owner = ownerOf(tokenId);

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
         
         ERC721Creator._burn(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Creator) returns (string memory) {
        return ERC721Creator.tokenURI(tokenId);
    }
        
}