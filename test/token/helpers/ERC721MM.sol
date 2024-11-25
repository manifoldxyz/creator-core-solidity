// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/// @author: manifold.xyz

import {ERC721MMBase} from "creator-core/token/ERC721MM/ERC721MMBase.sol";

contract MockERC721MM is ERC721MMBase {
    constructor(string memory _name, string memory _symbol) ERC721MMBase(_name, _symbol) {}

    function mint721(address to, uint256 tokenId) external {
        _721SafeMint(to, tokenId, 0);
    }

    function mint721(address to, uint256 tokenId, bytes memory data) external {
        _721SafeMint(to, tokenId, 0, data);
    }

    function mint721For1155(address to, uint256 tokenId) external {
        if (!_721Exists(tokenId - MAX_721_TOKEN_ID - 1)) {
            _721SafeMint(to, tokenId - MAX_721_TOKEN_ID - 1, 0);
        }
    }

    function mintBatch721For1155(address to, uint256[] calldata tokenIds) external {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (!_721Exists(tokenIds[i] - MAX_721_TOKEN_ID - 1)) {
                _721SafeMint(to, tokenIds[i] - MAX_721_TOKEN_ID - 1, 0);
            }
        }
    }

    function burn721(uint256 tokenId) external {
        _721Burn(tokenId);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(_721Exists(tokenId), "ERC721: invalid token ID");
        return "";
    }

    function mint1155(address account, uint256 id, uint256 amount, bytes calldata data) external {
        _1155Mint(account, id, amount, data);
    }

    function mintBatch1155(address account, uint256[] calldata id, uint256[] calldata amount, bytes calldata data)
        external
    {
        _1155MintBatch(account, id, amount, data);
    }

    function burn1155(address account, uint256 id, uint256 amount) external {
        _1155Burn(account, id, amount);
    }

    function burnBatch1155(address account, uint256[] calldata id, uint256[] calldata amount) external {
        _1155BurnBatch(account, id, amount);
    }

    function uri(uint256) external pure override returns (string memory) {
        return "";
    }
}
