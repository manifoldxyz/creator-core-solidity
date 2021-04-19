// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";
import "openzeppelin-solidity/contracts/utils/structs/EnumerableSet.sol";
import "./IERC721Creator.sol";
import "./IERC721CreatorExtension.sol";
import "./IERC721CreatorMintPermissions.sol";
import "./access/AdminControl.sol";

contract ERC721Creator is ReentrancyGuard, ERC721Enumerable, AdminControl, IERC721Creator {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 _tokenCount = 0;

    // Track registered extensions data
    EnumerableSet.AddressSet private _extensions;
    mapping (address => address) private _extensionPermissions;
    
    // For enumerating tokens for a given extension
    mapping (address => uint256) private _extensionBalances;
    mapping (address => mapping(uint256 => uint256)) private _extensionTokens;
    mapping (uint256 => uint256) private _extensionTokensIndex;

    // For enumerating an extension's tokens for an owner
    mapping (address => mapping(address => uint256)) private _extensionBalancesByOwner;
    mapping (address => mapping(address => mapping(uint256 => uint256))) private _extensionTokensByOwner;
    mapping (uint256 => uint256) private _extensionTokensIndexByOwner;

    // For tracking which extension a token was minted by
    mapping (uint256 => address) private _tokenExtension;

    // The baseURI for a given extension
    mapping (address => string) private _extensionBaseURI;

    // Mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    modifier extensionRequired() {
        require(_extensions.contains(msg.sender), "ERC721Creator: Must be registered extension");
        _;
    }   

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721Enumerable, AdminControl) returns (bool) {
        return interfaceId == type(IERC721Creator).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Creator-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory) {
        address[] memory extensions = new address[](_extensions.length());
        for (uint i = 0; i < _extensions.length(); i++) {
            extensions[i] = _extensions.at(i);
        }
        return extensions;
    }

    /**
     * @dev See {IERC721Creator-totalSupplyOfExtension}.
     */
    function totalSupplyOfExtension(address extension) public view virtual override returns (uint256) {
        return _extensionBalances[extension];
    }

    /**
     * @dev See {IERC721Creator-tokenByIndexOfExtension}.
     */
    function tokenByIndexOfExtension(address extension, uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupplyOfExtension(extension), "ERC721Creator: Index out of bounds");
        return _extensionTokens[extension][index];
    }

    /**
     * @dev See {IERC721Creator-extensionBalanceOf}.
     */
    function extensionBalanceOf(address extension, address owner) public view virtual override returns (uint256) {
        return _extensionBalancesByOwner[extension][owner];
    }

    /*
     * @dev See {IERC721Cerator-extensionTokenOfOwnerByIndex}.
     */
    function extensionTokenOfOwnerByIndex(address extension, address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < extensionBalanceOf(extension, owner), "ERC721Creator: Index out of bounds");
        return _extensionTokensByOwner[extension][owner][index];
    }

    /**
     * @dev See {IERC721Creator-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired returns (bool) {
        require(ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtension).interfaceId), "ERC721Creator: Must implement IERC721CreatorExtension");
        _extensionBaseURI[extension] = baseURI;
        emit ExtensionRegistered(extension, msg.sender);
        return _extensions.add(extension);
    }

    /**
     * @dev See {IERC721Creator-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired returns (bool) {
        emit ExtensionUnregistered(extension, msg.sender);
        return _extensions.remove(extension);
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override extensionRequired {
        _extensionBaseURI[msg.sender] = uri;
    }

    /**
     * @dev See {IERC721Creator-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override extensionRequired {
        require(_tokenExtension[tokenId] == msg.sender, "ERC721Creator: Invalid token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev See {IERC721Creator-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
         require(_extensions.contains(extension), "ERC721Creator: Invalid extension");
         require(permissions == address(0x0) || ERC165Checker.supportsInterface(permissions, type(IERC721CreatorMintPermissions).interfaceId), "ERC721Creator: Invalid address");
         if (_extensionPermissions[extension] != permissions) {
             _extensionPermissions[extension] = permissions;
             emit MintPermissionsUpdated(extension, permissions, msg.sender);
         }
    }

    /**
     * @dev See {IERC721Creator-mint}.
     */
    function mint(address to) external override nonReentrant extensionRequired virtual returns(uint256) {
        _tokenCount++;
        uint256 tokenId = _tokenCount;
        address permissions = _extensionPermissions[msg.sender];

        if (permissions != address(0x0)) {
            IERC721CreatorMintPermissions(permissions).approveMint(msg.sender, tokenId, to);
        }

        // Track the extension that minted the token
        _tokenExtension[tokenId] = msg.sender;

        // Add to extension token tracking
        uint256 length = totalSupplyOfExtension(msg.sender);
        _extensionTokens[msg.sender][length] = tokenId;
        _extensionTokensIndex[tokenId] = length;
        _extensionBalances[msg.sender] += 1;

        // Add to extension token tracking by owner
        uint256 lengthByOwner = extensionBalanceOf(msg.sender, to);
        _extensionTokensByOwner[msg.sender][to][lengthByOwner] = tokenId;
        _extensionTokensIndexByOwner[tokenId] = lengthByOwner;
        _extensionBalancesByOwner[msg.sender][to] += 1;        

        _safeMint(to, tokenId);

        return tokenId;
    }
    
    /**
     * @dev See {IERC721Creator-burn}.
     */
    function burn(uint256 tokenId) external override nonReentrant virtual {
        address tokenExtension_ = _tokenExtension[tokenId];
        address owner = ownerOf(tokenId);

        /*************************************************
         *  START: Remove from extension token tracking
         *************************************************/

        uint256 lastTokenIndex = totalSupplyOfExtension(tokenExtension_) - 1;
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

        uint256 lastTokenIndexByOwner = extensionBalanceOf(tokenExtension_, owner) - 1;
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
         
        // Delete token origin extension tracking
        delete _tokenExtension[tokenId];

        _burn(tokenId);

        // Clear metadata (if any)
         if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        
        // Callback to originating extension
        IERC721CreatorExtension(tokenExtension_).onBurn(owner, tokenId);
    }
    
    /**
     * @dev See {IERC721Creator-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) external view virtual override returns (address) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenExtension[tokenId];
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        return string(abi.encodePacked(_extensionBaseURI[_tokenExtension[tokenId]], tokenId.toString()));
    }
    
}