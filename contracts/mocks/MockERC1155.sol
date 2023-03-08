// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "../token/ERC1155/ERC1155Base.sol";

contract MockERC1155 is ERC1155Base {

    constructor (string memory uri_) ERC1155Base("", ""){
    }

    function testMint(address account, uint256 id, uint256 amount, bytes calldata data) external {
        _mint(account, id, amount, data);
    }

    function testMintBatch(address account, uint256[] calldata id, uint256[] calldata amount, bytes calldata data) external {
        _mintBatch(account, id, amount, data);
    }

    function uri(uint256) external pure override returns (string memory) {
        return "";
    }


}
