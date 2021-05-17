// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import "manifoldxyz-libraries-solidity/contracts/access/AdminControl.sol";
import "./core/ERC1155CreatorCore.sol";

/**
 * @dev ERC1155Creator implementation
 */
contract ERC1155Creator is AdminControl, ERC1155, ERC1155CreatorCore {

    constructor (string memory uri_) ERC1155(uri_) {
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155CreatorCore, AdminControl) returns (bool) {
        return ERC1155CreatorCore.supportsInterface(interfaceId) || ERC1155.supportsInterface(interfaceId) || AdminControl.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory) internal virtual override {
        _approveTransfer(from, to, ids, amounts);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI) external override adminRequired nonBlacklistRequired(extension) {
        _registerExtension(extension, baseURI, false);
    }

    /**
     * @dev See {ICreatorCore-registerExtension}.
     */
    function registerExtension(address extension, string calldata baseURI, bool baseURIIdentical) external override adminRequired nonBlacklistRequired(extension) {
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
    function setBaseTokenURIExtension(string calldata uri_) external override extensionRequired {
        _setBaseTokenURIExtension(uri_, false);
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURIExtension}.
     */
    function setBaseTokenURIExtension(string calldata uri_, bool identical) external override extensionRequired {
        _setBaseTokenURIExtension(uri_, identical);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefixExtension}.
     */
    function setTokenURIPrefixExtension(string calldata prefix) external override extensionRequired {
        _setTokenURIPrefixExtension(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256 tokenId, string calldata uri_) external override extensionRequired {
        _setTokenURIExtension(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIExtension}.
     */
    function setTokenURIExtension(uint256[] memory tokenIds, string[] calldata uris) external override extensionRequired {
        require(tokenIds.length == uris.length, "ERC1155Creator: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURIExtension(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {ICreatorCore-setBaseTokenURI}.
     */
    function setBaseTokenURI(string calldata uri_) external override adminRequired {
        _setBaseTokenURI(uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURIPrefix}.
     */
    function setTokenURIPrefix(string calldata prefix) external override adminRequired {
        _setTokenURIPrefix(prefix);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256 tokenId, string calldata uri_) external override adminRequired {
        _setTokenURI(tokenId, uri_);
    }

    /**
     * @dev See {ICreatorCore-setTokenURI}.
     */
    function setTokenURI(uint256[] memory tokenIds, string[] calldata uris) external override adminRequired {
        require(tokenIds.length == uris.length, "ERC1155Creator: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            _setTokenURI(tokenIds[i], uris[i]);            
        }
    }

    /**
     * @dev See {ICreatorCore-setMintPermissions}.
     */
    function setMintPermissions(address extension, address permissions) external override adminRequired {
        _setMintPermissions(extension, permissions);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseNew}.
     */
    function mintBaseNew(address to, uint256 amount) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBaseNew(to, amount, "");
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseNew}.
     */
    function mintBaseNew(address to, uint256 amount, string calldata uri_) public virtual override nonReentrant adminRequired returns(uint256) {
        return _mintBaseNew(to, amount, uri_);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseBatchNew}.
     */
    function mintBaseBatchNew(address to, uint256[] calldata amounts) public virtual override nonReentrant adminRequired returns(uint256[] memory) {
        return _mintBaseBatchNew(to, amounts, new string[](0));
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseBatchNew}.
     */
    function mintBaseBatchNew(address to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant adminRequired returns(uint256[] memory) {
        require(amounts.length == uris.length, "ERC1155Creator: Invalid input");
        return _mintBaseBatchNew(to, amounts, uris);
    }

    /**
     * @dev Mint token with no extension
     */
    function _mintBaseNew(address to, uint256 amount, string memory uri_) internal virtual returns(uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        // Track the extension that minted the token
        _tokensExtension[tokenId] = address(this);

        _mint(to, tokenId, amount, new bytes(0));

        if (bytes(uri_).length > 0) {
            _tokenURIs[tokenId] = uri_;
        }

        // Call post mint
        _postMint(_createSingletonArray(tokenId), _createSingletonArray(amount));
        return tokenId;
    }

    /**
     * @dev Mint token with no extension (batch)
     */
    function _mintBaseBatchNew(address to, uint256[] calldata amounts, string[] memory uris) internal returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](amounts.length);
        for (uint i = 0; i < amounts.length; i++) {
            _tokenCount++;
            tokenIds[i] = _tokenCount;
        }
        _mintBatch(to, tokenIds, amounts, new bytes(0));

        if (uris.length > 0) {
            for (uint i = 0; i < amounts.length; i++) {
                _tokenURIs[tokenIds[i]] = uris[i];
            }
        }
        _postMint(tokenIds, amounts);
        return tokenIds;
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseExisting}.
     */
    function mintBaseExisting(address to, uint256 tokenId, uint256 amount) public virtual override nonReentrant adminRequired {
        require(_tokensExtension[tokenId] == address(this), "ERC1155Creator: Specified token was created by an extension");
        _mint(to, tokenId, amount, new bytes(0));
        // Call post mint
        _postMint(_createSingletonArray(tokenId), _createSingletonArray(amount));
    }

    /**
     * @dev See {IERC1155CreatorCore-mintBaseExisting}.
     */
    function mintBaseBatchExisting(address to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant adminRequired {
        require(tokenIds.length == amounts.length, "ERC1155Creator: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == address(this), "ERC1155Creator: A specified token was created by an extension");
        }
        _mintBatch(to, tokenIds, amounts, new bytes(0));
        // Call post mint
        _postMint(tokenIds, amounts);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionNew}.
     */
    function mintExtensionNew(address to, uint256 amount) public virtual override nonReentrant extensionRequired returns(uint256) {
        return _mintExtensionNew(to, amount, "");
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionNew}.
     */
    function mintExtensionNew(address to, uint256 amount, string calldata uri_) public virtual override nonReentrant extensionRequired returns(uint256) {
        return _mintExtensionNew(to, amount, uri_);
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionBatchNew}.
     */
    function mintExtensionBatchNew(address to, uint256[] calldata amounts) public virtual override nonReentrant extensionRequired returns(uint256[] memory) {
        return _mintExtensionBatchNew(to, amounts, new string[](0));
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionBatchNew}.
     */
    function mintExtensionBatchNew(address to, uint256[] calldata amounts, string[] calldata uris) public virtual override nonReentrant extensionRequired returns(uint256[] memory tokenIds) {
        require(amounts.length == uris.length, "ERC1155Creator: Invalid input");
        return _mintExtensionBatchNew(to, amounts, uris);
    }
    
    /**
     * @dev Mint token via extension
     */
    function _mintExtensionNew(address to, uint256 amount, string memory uri_) internal virtual returns(uint256 tokenId) {
        _tokenCount++;
        tokenId = _tokenCount;

        // Track the extension that minted the token
        _tokensExtension[tokenId] = msg.sender;

        _checkMintPermissions(to, _createSingletonArray(tokenId), _createSingletonArray(amount));

        _mint(to, tokenId, amount, new bytes(0));

        if (bytes(uri_).length > 0) {
            _tokenURIs[tokenId] = uri_;
        }
        
        // Call post mint
        _postMint(_createSingletonArray(tokenId), _createSingletonArray(amount));
        return tokenId;
    }

    /**
     * @dev Mint token with extension (batch)
     */
    function _mintExtensionBatchNew(address to, uint256[] calldata amounts, string[] memory uris) internal returns(uint256[] memory tokenIds) {
        tokenIds = new uint256[](amounts.length);
        for (uint i = 0; i < amounts.length; i++) {
            _tokenCount++;
            tokenIds[i] = _tokenCount;
            // Track the extension that minted the token
            _tokensExtension[_tokenCount] = msg.sender;
        }

        _checkMintPermissions(to, tokenIds, amounts);

        _mintBatch(to, tokenIds, amounts, new bytes(0));

        if (uris.length > 0) {
            for (uint i = 0; i < amounts.length; i++) {
                _tokenURIs[tokenIds[i]] = uris[i];
            }
        }
        _postMint(tokenIds, amounts);
        return tokenIds;
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionExisting}.
     */
    function mintExtensionExisting(address to, uint256 tokenId, uint256 amount) public virtual override nonReentrant adminRequired {
        require(_tokensExtension[tokenId] == address(this), "ERC1155Creator: Specified token was created by an extension");
        _checkMintPermissions(to, _createSingletonArray(tokenId), _createSingletonArray(amount));
        _mint(to, tokenId, amount, new bytes(0));
        // Call post mint
        _postMint(_createSingletonArray(tokenId), _createSingletonArray(amount));
    }

    /**
     * @dev See {IERC1155CreatorCore-mintExtensionExisting}.
     */
    function mintExtensionBatchExisting(address to, uint256[] calldata tokenIds, uint256[] calldata amounts) public virtual override nonReentrant adminRequired {
        require(tokenIds.length == amounts.length, "ERC1155Creator: Invalid input");
        for (uint i = 0; i < tokenIds.length; i++) {
            require(_tokensExtension[tokenIds[i]] == address(this), "ERC1155Creator: A specified token was created by an extension");
        }
        _checkMintPermissions(to, tokenIds, amounts);
        _mintBatch(to, tokenIds, amounts, new bytes(0));
        // Call post mint
        _postMint(tokenIds, amounts);
    }

    /**
     * @dev See {IERC1155CreatorCore-tokenExtension}.
     */
    function tokenExtension(uint256 tokenId) public view virtual override returns (address) {
        return _tokenExtension(tokenId);
    }

    /**
     * @dev See {IERC1155CreatorCore-burn}.
     */
    function burn(address account, uint256 tokenId, uint256 amount) public virtual override nonReentrant {
        require(account == msg.sender || isApprovedForAll(account, msg.sender), "ERC1155Creator: caller is not owner nor approved");
        _burn(account, tokenId, amount);
        _postBurn(account, _createSingletonArray(tokenId), _createSingletonArray(amount));
    }

    /**
     * @dev See {IERC1155CreatorCore-burnBatch}.
     */
    function burnBatch(address account, uint256[] memory tokenIds, uint256[] memory amounts) public virtual override nonReentrant {
        require(tokenIds.length == amounts.length, "ERC1155Creator: Invalid input");
        _burnBatch(account, tokenIds, amounts);
        _postBurn(account, tokenIds, amounts);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(address(this), receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyalties}.
     */
    function setRoyalties(uint256 tokenId, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyalties(tokenId, receivers, basisPoints);
    }

    /**
     * @dev See {ICreatorCore-setRoyaltiesExtension}.
     */
    function setRoyaltiesExtension(address extension, address payable[] calldata receivers, uint256[] calldata basisPoints) external override adminRequired {
        _setRoyaltiesExtension(extension, receivers, basisPoints);
    }

    /**
     * @dev {See ICreatorCore-getRoyalties}.
     */
    function getRoyalties(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev {See ICreatorCore-getFees}.
     */
    function getFees(uint256 tokenId) external view virtual override returns (address payable[] memory, uint256[] memory) {
        return _getRoyalties(tokenId);
    }

    /**
     * @dev {See ICreatorCore-getFeeRecipients}.
     */
    function getFeeRecipients(uint256 tokenId) external view virtual override returns (address payable[] memory) {
        return _getRoyaltyReceivers(tokenId);
    }

    /**
     * @dev {See ICreatorCore-getFeeBps}.
     */
    function getFeeBps(uint256 tokenId) external view virtual override returns (uint[] memory) {
        return _getRoyaltyBPS(tokenId);
    }
    
    /**
     * @dev {See ICreatorCore-royaltyInfo}.
     */
    function royaltyInfo(uint256 tokenId, uint256 value, bytes calldata) external view virtual override returns (address, uint256, bytes memory) {
        return _getRoyaltyInfo(tokenId, value);
    } 

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return _tokenURI(tokenId);
    }
    
}