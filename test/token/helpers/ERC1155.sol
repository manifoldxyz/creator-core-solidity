// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import {ERC1155Base} from "creator-core/token/ERC1155/ERC1155Base.sol";

contract MockERC1155 is ERC1155Base {
    constructor(string memory uri_) ERC1155Base("", "") {}

    function mint(address account, uint256 id, uint256 amount, bytes calldata data) external {
        _mint(account, id, amount, data);
    }

    function mintBatch(address account, uint256[] calldata id, uint256[] calldata amount, bytes calldata data)
        external
    {
        _mintBatch(account, id, amount, data);
    }

    function burn(address account, uint256 id, uint256 amount) external {
        _burn(account, id, amount);
    }

    function burnBatch(address account, uint256[] calldata id, uint256[] calldata amount) external {
        _burnBatch(account, id, amount);
    }

    function uri(uint256) external pure override returns (string memory) {
        return "";
    }
}
