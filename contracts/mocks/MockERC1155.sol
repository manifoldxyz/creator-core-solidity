// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {

    constructor (string memory uri_) ERC1155(uri_){
    }

    function testMint(address account, uint256 id, uint256 amount, bytes calldata data) external {
        _mint(account, id, amount, data);
    }
}
