// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {AdminControlUpgradeable} from "manifoldxyz/libraries-solidity/access/AdminControlUpgradeable.sol";
import {EnumerableSet} from "openzeppelin/utils/structs/EnumerableSet.sol";
import {ERC721CreatorCore} from "./core/ERC721CreatorCore.sol";
import {ERC721MMCore} from "./token/ERC721MM/ERC721MMCore.sol";
import {ERC721MMUpgradeable} from "./token/ERC721MM/ERC721MMUpgradeable.sol";

/**
 * @dev ERC721MMCreator implementation
 */
contract ERC721MMCreatorImplementation is AdminControlUpgradeable, ERC721MMUpgradeable, ERC721CreatorCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * Initializer
     */
    function initialize(string memory _name, string memory _symbol) public initializer {
        __ERC721MM_init(_name, _symbol);
        __Ownable_init();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721MMCore, ERC721CreatorCore, AdminControlUpgradeable)
        returns (bool)
    {
        return ERC721CreatorCore.supportsInterface(interfaceId) || ERC721MMCore.supportsInterface(interfaceId)
            || AdminControlUpgradeable.supportsInterface(interfaceId);
    }

    function _721BeforeTokenTransfer(address from, address to, uint256 tokenId, uint96 data)
        internal
        virtual
        override
    {
        _approveTransfer(from, to, tokenId, uint16(data));
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string memory baseURI) external override adminRequired {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string memory baseURI, bool baseURIIdentical)
        external
        override
        adminRequired
    {
        requireNonBlacklist(extension);
        _registerExtension(extension, baseURI, baseURIIdentical);
    }

    /**
     * @dev See {ICreatorCore-unregisterExtension}.
     */
    function unregisterExtension(address extension) external override adminRequired {
        _unregisterExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-blacklistExtension}.
     */
    function blacklistExtension(address extension) external override adminRequired {
        _blacklistExtension(extension);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string memory tokenUri) external override {
        requireExtension();
        _setBaseTokenURIExtension(tokenUri, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string memory tokenUri, bool identical) external override {
        requireExtension();
        _setBaseTokenURIExtension(tokenUri, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string memory prefix) external override {
        requireExtension();
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string memory tokenUri) external override {
        requireExtension();
        _setTokenURIExtension(tokenId, tokenUri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] memory tokenUris) external override {
        requireExtension();
        require(tokenIds.length == tokenUris.length, "Invalid input");
        for (uint256 i; i < tokenIds.length;) {
            _setTokenURIExtension(tokenIds[i], tokenUris[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string memory tokenUri) external override adminRequired {
        _setBaseTokenURI(tokenUri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string memory prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string memory tokenUri) external override adminRequired {
        _setTokenURI(tokenId, tokenUri);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] memory tokenUris) external override adminRequired {
        require(tokenIds.length == tokenUris.length, "Invalid input");
        for (uint256 i; i < tokenIds.length;) {
            _setTokenURI(tokenIds[i], tokenUris[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to) public virtual override nonReentrant adminRequired returns (uint256) {
        return _mintBase(to, "", 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBase}.
     */
    function mintBase(address to, string memory tokenUri)
        public
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256)
    {
        return _mintBase(to, tokenUri, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, uint16 count)
        public
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](count);
        uint256 firstTokenId = _tokenCount + 1;
        _tokenCount += count;

        for (uint256 i; i < count;) {
            tokenIds[i] = _mintBase(to, "", firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintBaseBatch}.
     */
    function mintBaseBatch(address to, string[] memory uris)
        public
        virtual
        override
        nonReentrant
        adminRequired
        returns (uint256[] memory tokenIds)
    {
        tokenIds = new uint256[](uris.length);
        uint256 firstTokenId = _tokenCount + 1;
        _tokenCount += uris.length;

        for (uint256 i; i < uris.length;) {
            tokenIds[i] = _mintBase(to, uris[i], firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Mint token with no extension
     */
    function _mintBase(address to, string memory tokenUri, uint256 tokenId) internal virtual returns (uint256) {
        if (tokenId == 0) {
            ++_tokenCount;
            tokenId = _tokenCount;
        }

        // Call pre mint
        _preMintBase(to, tokenId);

        _721SafeMint(to, tokenId, 0);

        if (bytes(tokenUri).length > 0) {
            _tokenURIs[tokenId] = tokenUri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to) public virtual override nonReentrant returns (uint256) {
        requireExtension();
        return _mintExtension(to, "", 0, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, string memory tokenUri) public virtual override nonReentrant returns (uint256) {
        requireExtension();
        return _mintExtension(to, tokenUri, 0, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtension}.
     */
    function mintExtension(address to, uint80 data) public virtual override nonReentrant returns (uint256) {
        requireExtension();
        return _mintExtension(to, "", data, 0);
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint16 count)
        public
        virtual
        override
        nonReentrant
        returns (uint256[] memory tokenIds)
    {
        requireExtension();
        tokenIds = new uint256[](count);
        uint256 firstTokenId = _tokenCount + 1;
        _tokenCount += count;

        for (uint256 i; i < count;) {
            tokenIds[i] = _mintExtension(to, "", 0, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, string[] memory uris)
        public
        virtual
        override
        nonReentrant
        returns (uint256[] memory tokenIds)
    {
        requireExtension();
        tokenIds = new uint256[](uris.length);
        uint256 firstTokenId = _tokenCount + 1;
        _tokenCount += uris.length;

        for (uint256 i; i < uris.length;) {
            tokenIds[i] = _mintExtension(to, uris[i], 0, firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IERC721CreatorCore-mintExtensionBatch}.
     */
    function mintExtensionBatch(address to, uint80[] memory data)
        public
        virtual
        override
        nonReentrant
        returns (uint256[] memory tokenIds)
    {
        requireExtension();
        tokenIds = new uint256[](data.length);
        uint256 firstTokenId = _tokenCount + 1;
        _tokenCount += data.length;

        for (uint256 i; i < data.length;) {
            tokenIds[i] = _mintExtension(to, "", data[i], firstTokenId + i);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Mint token via extension
     */
    function _mintExtension(address to, string memory tokenUri, uint80 data, uint256 tokenId)
        internal
        virtual
        returns (uint256)
    {
        if (tokenId == 0) {
            ++_tokenCount;
            tokenId = _tokenCount;
        }

        _checkMintPermissions(to, tokenId);
        // Call pre mint
        _preMintExtension(to, tokenId);

        _721SafeMint(to, tokenId, data << 16 | _extensionToIndex[msg.sender]);

        if (bytes(tokenUri).length > 0) {
            _tokenURIs[tokenId] = tokenUri;
        }

        return tokenId;
    }

    /**
     * @dev See {IERC721CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address extension) {
        require(_721Exists(tokenId), "Nonexistent token");
        extension = _tokenExtension(tokenId);
        require(extension != address(0), "No extension for token");
        require(!_blacklistedExtensions.contains(extension), "Extension blacklisted");
    }

    /**
     * @dev See {IERC721CreatorCore-burn}.
     */
    function burn(uint256 tokenId) public virtual override nonReentrant {
        require(_721IsApprovedOrOwner(msg.sender, tokenId), "Caller is not owner or approved");
        address owner = ownerOf(tokenId);
        address extension = _tokenExtension(tokenId);
        _721Burn(tokenId);
        _postBurn(owner, tokenId, extension);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] memory receivers, uint256[] memory basisPoints)
        external
        override
        adminRequired
    {
        _setRoyaltiesExtension(address(0), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] memory receivers, uint256[] memory basisPoints)
        external
        override
        adminRequired
    {
        require(_721Exists(tokenId), "Nonexistent token");
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] memory receivers, uint256[] memory basisPoints)
        external
        override
        adminRequired
    {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address payable[] memory, uint256[] memory)
    {
        require(_721Exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId)
        external
        view
        virtual
        override
        returns (address payable[] memory, uint256[] memory)
    {
        require(_721Exists(tokenId), "Nonexistent token");
        return _getRoyalties(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        require(_721Exists(tokenId), "Nonexistent token");
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev See {ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint256[] memory) {
        require(_721Exists(tokenId), "Nonexistent token");
        return _getRoyaltyBPS(tokenId);
    }

    /**
     * @dev See {ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value) external view virtual override returns (address, uint256) {
        require(_721Exists(tokenId), "Nonexistent token");
        return _getRoyaltyInfo(tokenId, value);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_721Exists(tokenId), "Nonexistent token");
        return _tokenURI(tokenId);
    }

    /**
     * @dev See {IERC1155Metadata-uri}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        uint256 tokenId721 = tokenId - _OFFSET_1155_TOKEN_ID;
        require(_721Exists(tokenId721), "Nonexistent token");
        return _tokenURI(tokenId721);
    }

    /**
     * @dev See {ICreatorCore-setApproveTransfer}.
     */
    function setApproveTransfer(address extension) external override adminRequired {
        _setApproveTransferBase(extension);
    }

    function _tokenExtension(uint256 tokenId) internal view override returns (address) {
        uint16 extensionIndex = uint16(_721TokenData[tokenId].data);
        if (extensionIndex == 0) return address(0);
        return _indexToExtension[extensionIndex];
    }

    /**
     * @dev See {IERC721CreatorCore-tokenData}.
     */
    function tokenData(uint256 tokenId) external view returns (uint80) {
        return uint80(_721TokenData[tokenId].data >> 16);
    }

    // 1155 token functions
    function mint1155(address to, uint256 tokenId, uint256 amount, bytes memory data) public nonReentrant {
        _1155Mint(to, tokenId, amount, data);
    }

    function mintBatch1155(address to, uint256[] memory tokenIds, uint256[] memory amounts, bytes memory data)
        public
        nonReentrant
    {
        _1155MintBatch(to, tokenIds, amounts, data);
    }

    /**
     * @dev See {IERC1155-burn}.
     */
    function burn(address account, uint256[] memory tokenIds, uint256[] memory amounts) public virtual nonReentrant {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "Caller is not owner or approved");
        require(tokenIds.length == amounts.length, "Invalid input");
        if (tokenIds.length == 1) {
            _1155Burn(account, tokenIds[0], amounts[0]);
        } else {
            _1155BurnBatch(account, tokenIds, amounts);
        }
    }
}
