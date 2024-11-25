// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC1155Receiver} from "openzeppelin/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "openzeppelin/token/ERC721/IERC721Receiver.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {ERC165, IERC165} from "openzeppelin/utils/introspection/ERC165.sol";
import {IERC721MM} from "./IERC721MM.sol";

/**
 * @dev Implementation of Non-Fungible Token Standard and Multi-Token Standard
 * https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard
 * https://eips.ethereum.org/EIPS/eip-1155[ERC1155] Multi-Token Standard
 */
abstract contract ERC721MMCore is ERC165, IERC721MM {
    using Address for address;

    struct TokenData721 {
        address owner;
        uint96 data;
    }

    // The first token ID to use for ERC1155 tokens
    uint256 public constant MAX_721_TOKEN_ID = 999999;
    uint256 internal constant _OFFSET_1155_TOKEN_ID = 1000000;

    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from token ID to token data
    mapping(uint256 => TokenData721) internal _721TokenData;

    // Mapping owner address to token count
    mapping(address => uint256) private _721Balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _721TokenApprovals;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _1155Balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721-IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (owner == operator) revert CannotSetForSelf();
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0xd9b67a26
            || interfaceId == 0x0e89341c || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Check if the address is not zero and revert if it is.
     */
    function _checkNonZeroAddress(address addr) private pure {
        if (addr == address(0)) revert InvalidAddress();
    }

    function _checkMismatchInputLengthsUint256(uint256[] memory arr1, uint256[] memory arr2) private pure {
        if (arr1.length != arr2.length) revert MismatchInputLength();
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        _checkNonZeroAddress(owner);
        return _721Balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        if (!_721Exists(tokenId)) revert InvalidTokenId();
        return _721TokenData[tokenId].owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721MMCore.ownerOf(tokenId);
        if (to == owner) revert CannotSetForSelf();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert PermissionDenied();

        _721Approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_721Exists(tokenId)) revert InvalidTokenId();
        return _721TokenApprovals[tokenId];
    }
    /**
     * @dev See {IERC721-transferFrom}.
     */

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        if (!_721IsApprovedOrOwner(msg.sender, tokenId)) revert PermissionDenied();
        _721Transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        if (!_721IsApprovedOrOwner(msg.sender, tokenId)) revert PermissionDenied();
        _721SafeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _721SafeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _721Transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _721Exists(uint256 tokenId) internal view virtual returns (bool) {
        return _721TokenData[tokenId].owner != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _721IsApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721MMCore.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _721SafeMint(address to, uint256 tokenId, uint96 tokenData) internal virtual {
        _721SafeMint(to, tokenId, tokenData, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _721SafeMint(address to, uint256 tokenId, uint96 tokenData, bytes memory data) internal virtual {
        if (tokenId == 0 || tokenId > MAX_721_TOKEN_ID) revert InvalidTokenId();
        _checkNonZeroAddress(to);
        if (_721Exists(tokenId)) revert TokenAlreadyMinted();

        _721BeforeTokenTransfer(address(0), to, tokenId, tokenData);

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _721Balances[to] += 1;
        }

        _721TokenData[tokenId] = TokenData721({owner: to, data: tokenData});
        emit Transfer(address(0), to, tokenId);

        _721AfterTokenTransfer(address(0), to, tokenId, tokenData);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _721Burn(uint256 tokenId) internal virtual {
        address owner = _721TokenData[tokenId].owner;
        uint96 data = _721TokenData[tokenId].data;
        _721BeforeTokenTransfer(owner, address(0), tokenId, data);

        // Clear approvals
        _721Approve(address(0), tokenId);

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _721Balances[owner] -= 1;
        }
        delete _721TokenData[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _721AfterTokenTransfer(owner, address(0), tokenId, data);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _721Transfer(address from, address to, uint256 tokenId) internal virtual {
        if (_721TokenData[tokenId].owner != from) revert PermissionDenied();
        _checkNonZeroAddress(to);

        _721BeforeTokenTransfer(from, to, tokenId, _721TokenData[tokenId].data);

        // Clear approvals from the previous owner
        _721Approve(address(0), tokenId);

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _721Balances[from] -= 1;
            _721Balances[to] += 1;
        }
        _721TokenData[tokenId].owner = to;

        emit Transfer(from, to, tokenId);

        _721AfterTokenTransfer(from, to, tokenId, _721TokenData[tokenId].data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _721Approve(address to, uint256 tokenId) internal virtual {
        _721TokenApprovals[tokenId] = to;
        emit Approval(ERC721MMCore.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * Reverts if the call does not return the expected magic value.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) revert TransferFailed();
            } catch {
                revert TransferFailed();
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _721BeforeTokenTransfer(address from, address to, uint256 tokenId, uint96 tokenData) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _721AfterTokenTransfer(address from, address to, uint256 tokenId, uint96 tokenData) internal virtual {}

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        _checkNonZeroAddress(account);
        return _1155Balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory batchBalances)
    {
        if (accounts.length != ids.length) revert MismatchInputLength();

        batchBalances = new uint256[](accounts.length);

        for (uint256 i; i < accounts.length;) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        public
        virtual
        override
    {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert PermissionDenied();
        _1155SafeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert PermissionDenied();
        _1155SafeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _1155SafeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
        internal
        virtual
    {
        _checkNonZeroAddress(to);

        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _1155BeforeTokenTransfer(msg.sender, from, to, ids, amounts, data);

        _1155Transfer(from, to, id, amount);

        emit TransferSingle(msg.sender, from, to, id, amount);

        _1155AfterTokenTransfer(msg.sender, from, to, ids, amounts, data);

        _checkOnERC1155Received(msg.sender, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _1155SafeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        _checkMismatchInputLengthsUint256(ids, amounts);
        _checkNonZeroAddress(to);

        _1155BeforeTokenTransfer(msg.sender, from, to, ids, amounts, data);

        for (uint256 i; i < ids.length;) {
            _1155Transfer(from, to, ids[i], amounts[i]);
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        _1155AfterTokenTransfer(msg.sender, from, to, ids, amounts, data);

        _checkOnERC1155BatchReceived(msg.sender, from, to, ids, amounts, data);
    }

    /**
     * @dev Internal function to transfer `amount` tokens of token type `id` from `from` to `to`.
     */
    function _1155Transfer(address from, address to, uint256 id, uint256 amount) private {
        uint256 fromBalance = _1155Balances[id][from];
        if (fromBalance < amount) revert InsufficientBalance();
        unchecked {
            _1155Balances[id][from] = fromBalance - amount;
        }
        if (to != address(0)) _1155Balances[id][to] += amount;
    }

    function _1155CheckCanMintToken(uint256 id) private view {
        uint256 tokenId721 = id - _OFFSET_1155_TOKEN_ID;
        if (!_721Exists(tokenId721)) revert InvalidTokenId();
        if (msg.sender != ownerOf(tokenId721)) revert PermissionDenied();
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _1155Mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        _checkNonZeroAddress(to);
        _1155CheckCanMintToken(id);

        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _1155BeforeTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

        _1155Balances[id][to] += amount;
        emit TransferSingle(msg.sender, address(0), to, id, amount);

        _1155AfterTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

        _checkOnERC1155Received(msg.sender, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _1155MintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        virtual
    {
        _checkMismatchInputLengthsUint256(ids, amounts);
        _checkNonZeroAddress(to);

        _1155BeforeTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

        for (uint256 i; i < ids.length;) {
            uint256 id = ids[i];
            _1155CheckCanMintToken(id);
            _1155Balances[id][to] += amounts[i];
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        _1155AfterTokenTransfer(msg.sender, address(0), to, ids, amounts, data);

        _checkOnERC1155BatchReceived(msg.sender, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _1155Burn(address from, uint256 id, uint256 amount) internal virtual {
        _checkNonZeroAddress(from);

        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _1155BeforeTokenTransfer(msg.sender, from, address(0), ids, amounts, "");

        _1155Transfer(from, address(0), id, amount);

        emit TransferSingle(msg.sender, from, address(0), id, amount);

        _1155AfterTokenTransfer(msg.sender, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _1155BurnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        _checkMismatchInputLengthsUint256(ids, amounts);
        _checkNonZeroAddress(from);

        address operator = msg.sender;

        _1155BeforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i; i < ids.length;) {
            _1155Transfer(from, address(0), ids[i], amounts[i]);
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _1155AfterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _1155BeforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _1155AfterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Internal function to invoke {IER1155Receiver-onERC1155Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * Reverts if the call does not return the expected magic value.
     *
     * @param operator address initiating the transfer
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param id uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert TransferFailed();
                }
            } catch {
                revert TransferFailed();
            }
        }
    }

    /**
     * @dev Internal function to invoke {IER1155Receiver-onERC1155Received} on a target address.
     * The call is not executed if the target address is not a contract.
     * Reverts if the call does not return the expected magic value.
     *
     * @param operator address initiating the transfer
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param ids uint256 ID of the token to be transferred
     * @param amounts uint256 amount of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert TransferFailed();
                }
            } catch {
                revert TransferFailed();
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory array) {
        array = new uint256[](1);
        array[0] = element;
    }
}
