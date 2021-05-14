// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";
import "./extensions/IERC721CreatorExtensionBase.sol";
import "./extensions/IERC721CreatorExtensionBurnable.sol";
import "./extensions/IERC721CreatorExtensionTokenURI.sol";
import "./permissions/IERC721CreatorMintPermissions.sol";
import "./IERC721Creator.sol";

contract ERC721Creator is ReentrancyGuard, ERC721, AdminControl, IERC721Creator {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 _tokenCount = 0;

    // Track registered extensions data
    EnumerableSet.AddressSet private _extensions;
    EnumerableSet.AddressSet private _blacklistedExtensions;
    mapping (address => address) private _extensionPermissions;
    
    // For tracking which extension a token was minted by
    mapping (uint256 => address) internal _tokenExtension;

    // The baseURI for a given extension
    mapping (address => string) private _extensionBaseURI;
    mapping (address => bool) private _extensionBaseURIIdentical;

    // The prefix for any tokens with a uri configured
    mapping (address => string) private _extensionURIPrefix;

    // Mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    modifier extensionRequired() {
        require(_extensions.contains(msg.sender), "ERC721Creator: Must be registered extension");
        _;
    }

    /**
     * @dev Only allows non-blacklisted extensions
     */
    modifier nonBlacklistRequired(address extension) {
        require(!_blacklistedExtensions.contains(extension), "ERC721Creator: Extension blacklisted");
        _;
    }   

    constructor (string memory _name, string memory _symbol) ERC721(_name, _symbol) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721, AdminControl) returns (bool) {
        return interfaceId == type(IERC721Creator).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Creator-getExtensions}.
     */
    function getExtensions() external view override returns (address[] memory extensions) {
        extensions = new address[](_extensions.length());
        for (uint i = 0; i < _extensions.length(); i++) {
            extensions[i] = _extensions.at(i);
        }
        return extensions;
    }

    /**
     * @dev See {IERC721Creator-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {IERC721Creator-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, baseURIIdentical);
    }


    function _registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) internal {
        require(ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionBase).interfaceId), "ERC721Creator: Extension must implement IERC721CreatorExtensionBase");
        if (!_extensions.contains(extension)) {
            _extensionBaseURI[extension] = baseURI;
            _extensionBaseURIIdentical[extension] = baseURIIdentical;
            emit ExtensionRegistered(extension, msg.sender);
            _extensions.add(extension);
        }
    }

    /**
     * @dev See {IERC721Creator-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
    }

    /**
     * @dev See {IERC721Creator-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
       require(extension != address(this), "ERC721Creator: Cannot blacklist yourself");
       if (_extensions.contains(extension)) {
           emit ExtensionUnregistered(extension, msg.sender);
           _extensions.remove(extension);
       }
       if (!_blacklistedExtensions.contains(extension)) {
           emit ExtensionBlacklisted(extension, msg.sender);
           _blacklistedExtensions.add(extension);
       }
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri) external override extensionRequired {
        _setBaseTokenURIExtension(uri, false);
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri, bool identical) external override extensionRequired {
        _setBaseTokenURIExtension(uri, identical);
    }

    function _setBaseTokenURIExtension(string calldata uri, bool identical) internal {
        _extensionBaseURI[msg.sender] = uri;
        _extensionBaseURIIdentical[msg.sender] = identical;
    }

    /**
     * @dev See {IERC721Creator-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override extensionRequired {
        _extensionURIPrefix[msg.sender] = prefix;
    }

    /**
     * @dev See {IERC721Creator-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri) external override extensionRequired {
        if (_tokenExtension[tokenId] == msg.sender) {
            _tokenURIs[tokenId] = uri;
        } else if (_tokenExtension[tokenId] != address(0)) {
            revert("ERC721Creator: Only creator extension can set token URI");
        } else {
        require(_tokenExtension[tokenId] == msg.sender, "ERC721Creator: Invalid token");
            revert("ERC721Creator: Invalid token");
        }
    }

    /**
     * @dev See {IERC721Creator-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri) external override adminRequired {
        _extensionBaseURI[address(this)] = uri;
    }

    /**
     * @dev See {IERC721Creator-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _extensionURIPrefix[address(this)] = prefix;
    }

    /**
     * @dev See {IERC721Creator-setTokenURIBase}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) external override adminRequired {
        if (_tokenExtension[tokenId] == address(this)) {
            _tokenURIs[tokenId] = uri;
        } else if (_tokenExtension[tokenId] != address(0)) {
            revert("ERC721Creator: Only creator extension can set token URI");
        } else {
            revert("ERC721Creator: Invalid token");
        }
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
     * @dev See {IERC721Creator-mintBase}.
     */
    function mintBase(address to) public override nonReentrant adminRequired virtual returns(uint256) {
        return _mintBase(to, "");
    }

    /**
     * @dev See {IERC721Creator-mintBase}.
     */
    function mintBase(address to, string calldata uri) public override nonReentrant adminRequired virtual returns(uint256) {
        return _mintBase(to, uri);
    }

    /**
     * @dev See {IERC721Creator-mintBaseBatch}.
     */
    function mintBaseBatch(address to, uint16 count) public override nonReentrant adminRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _mintBase(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721Creator-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] calldata uris) public override nonReentrant adminRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintBase(to, uris[i]);
        }
        return tokenIds;
    }

    function _mintBase(address to, string memory uri) internal virtual returns(uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        // Track the extension that minted the token
        _tokenExtension[tokenId] = address(this);

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721Creator-mintExtension}.
     */
    function mintExtension(address to) public override nonReentrant extensionRequired virtual returns(uint256) {
        return _mintExtension(to, "");
    }

    /**
     * @dev See {IERC721Creator-mintExtension}.
     */
    function mintExtension(address to, string calldata uri) public override nonReentrant extensionRequired virtual returns(uint256) {
        return _mintExtension(to, uri);
    }

    /**
     * @dev See {IERC721Creator-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count) public override nonReentrant extensionRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](count);
        for (uint16 i = 0; i < count; i++) {
            tokenIds[i] = _mintExtension(to, "");
        }
        return tokenIds;
    }

    /**
     * @dev See {IERC721Creator-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] calldata uris) public override nonReentrant extensionRequired virtual returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](uris.length);
        for (uint i = 0; i < uris.length; i++) {
            tokenIds[i] = _mintExtension(to, uris[i]);
        }
        return tokenIds;
    }

    function _mintExtension(address to, string memory uri) internal virtual returns(uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;
        address permissions = _extensionPermissions[msg.sender];

        if (permissions != address(0x0)) {
            IERC721CreatorMintPermissions(permissions).approveMint(msg.sender, tokenId, to);
        }

        // Track the extension that minted the token
        _tokenExtension[tokenId] = msg.sender;

        _safeMint(to, tokenId);

        if (bytes(uri).length > 0) {
            _tokenURIs[tokenId] = uri;
        }

        return tokenId;
    }
    
    /**
     * @dev See {IERC721Creator-burn}.
     */
    function burn(uint256 tokenId) public override nonReentrant virtual {
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) virtual {
        address extension = _tokenExtension[tokenId];
        address owner = ownerOf(tokenId);
         
        // Delete token origin extension tracking
        delete _tokenExtension[tokenId];

        ERC721._burn(tokenId);

        // Clear metadata (if any)
         if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        
        // Callback to originating extension if needed
        if (extension != address(this)) {
           if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionBurnable).interfaceId)) {
               IERC721CreatorExtensionBurnable(extension).onBurn(owner, tokenId);
           }
        }
    }
    
    /**
     * @dev See {IERC721Creator-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address extension) {
        require(_exists(tokenId), "Nonexistent token");

        extension = _tokenExtension[tokenId];

        require(extension != address(this), "ERC721Creator: No extension for token");
        require(!_blacklistedExtensions.contains(extension), "ERC721Creator: Extension blacklisted");

        return extension;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");

        address extension = _tokenExtension[tokenId];
        require(!_blacklistedExtensions.contains(extension), "ERC721Creator: Extension blacklisted");

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            if (bytes(_extensionURIPrefix[extension]).length != 0) {
                return string(abi.encodePacked(_extensionURIPrefix[extension],_tokenURIs[tokenId]));
            }
            return _tokenURIs[tokenId];
        }

        if (ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtensionTokenURI).interfaceId)) {
            return IERC721CreatorExtensionTokenURI(extension).tokenURI(address(this), tokenId);
        }

        if (!_extensionBaseURIIdentical[extension]) {
            return string(abi.encodePacked(_extensionBaseURI[extension], tokenId.toString()));
        } else {
            return _extensionBaseURI[extension];
        }
    }
    
}