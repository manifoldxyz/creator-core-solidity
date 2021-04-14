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
import "./access/AdminControl.sol";

contract ERC721Creator is ReentrancyGuard, ERC721Enumerable, AdminControl, IERC721Creator {
    using Strings for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint256 _tokenCount = 0;

    // Track registered extensions    
    EnumerableSet.AddressSet private _extensions;
    mapping (address => uint256) private _extensionBalances;
    mapping (address => mapping(uint256 => uint256)) private _extensionTokens;
    mapping (uint256 => uint256) private _extensionTokensIndex;
    mapping (uint256 => address) private _tokenExtension;
    mapping (address => string) private _extensionBaseURI;

    // Mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev Only allows registered extensions to call the specified function
     */
    modifier extensionRequired() {
        require(_extensions.contains(msg.sender), "ERC721Creator: Must be a registered extension to call this function");
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
        require(extension != address(0), "ERC721Creator: balance query for the zero address");
        return _extensionBalances[extension];
    }


    /**
     * @dev See {IERC721Creator-tokenByIndexOfExtension}.
     */
    function tokenByIndexOfExtension(address extension, uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupplyOfExtension(extension), "ERC721Creator: extension index out of bounds");
        return _extensionTokens[extension][index];
    }

    /**
     * @dev See {IERC721Creator-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired returns (bool) {
        require(ERC165Checker.supportsInterface(extension, type(IERC721CreatorExtension).interfaceId), "ERC721Creator: Must implement IERC721CreatorExtension");
        _extensionBaseURI[extension] = baseURI;
        return _extensions.add(extension);
    }

    /**
     * @dev See {IERC721Creator-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired returns (bool) {
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
        require(_tokenExtension[tokenId] == msg.sender, "ERC721Creator: Only callable by extension that created this token");
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev See {IERC721Creator-mint}.
     */
    function mint(address to) external override nonReentrant extensionRequired virtual returns(uint256) {
        _tokenCount++;
        uint256 tokenId = _tokenCount;

        // Add to extension token tracking
        uint256 length = totalSupplyOfExtension(msg.sender);
        _tokenExtension[tokenId] = msg.sender;
        _extensionTokens[msg.sender][length] = tokenId;
        _extensionTokensIndex[tokenId] = length;
        _extensionBalances[msg.sender] += 1;

        _safeMint(to, tokenId);

        return tokenId;
    }
    
    /**
     * @dev See {IERC721Creator-burn}.
     */
    function burn(uint256 tokenId) external override nonReentrant virtual {
        address tokenExtension = _tokenExtension[tokenId];

        // Remove from extension token tracking
        uint256 lastTokenIndex = totalSupplyOfExtension(tokenExtension) - 1;
        uint256 tokenIndex = _extensionTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _extensionTokens[tokenExtension][lastTokenIndex];

            _extensionTokens[tokenExtension][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _extensionTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        _extensionBalances[tokenExtension] -= 1;
        // This also deletes the contents at the last position of the array
        delete _extensionTokensIndex[tokenId];
        delete _extensionTokens[tokenExtension][lastTokenIndex];
        delete _tokenExtension[tokenId];

        _burn(tokenId);

        // Clear metadata (if any)
         if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        
        // Callback to originating extension
        require(IERC721CreatorExtension(tokenExtension).onBurn(tokenId));
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