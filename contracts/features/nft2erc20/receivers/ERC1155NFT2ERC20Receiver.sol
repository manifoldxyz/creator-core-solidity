// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/token/ERC1155/IERC1155.sol";
import "openzeppelin-solidity/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";

import "../INFT2ERC20.sol";

contract ERC1155NFT2ERC20Receiver is ERC1155Receiver {

    address _nft2erc20;
    mapping (address => bool) private _approved;

    constructor (address nft2erc20) {
        require(ERC165Checker.supportsInterface(nft2erc20, type(INFT2ERC20).interfaceId), "ERC1155NFT2ERC20Receiver: Must implement INFT2ERC20");
        _nft2erc20 = nft2erc20;
    }

    /*
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata
    ) external override returns(bytes4) {
        if (_approved[operator] != true) {
            IERC1155(operator).setApprovalForAll(_nft2erc20, true);
            _approved[operator] = true;
        }
        uint256[] memory args = new uint256[](2);
        args[0] = id;
        args[1] = value;
        INFT2ERC20(_nft2erc20).burnToken(operator, args, 'erc1155', from);
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata
    ) external override returns(bytes4) {
        require(ids.length == values.length, "ERC1155NFT2ERC20Receiver: mismatched data length");
        uint256[] memory args = new uint256[](2);
        for (uint i=0; i < ids.length; i++) {
            args[0] = ids[i];
            args[1] = values[i];
            INFT2ERC20(_nft2erc20).burnToken(operator, args, 'erc1155', from);
        }
        return this.onERC1155Received.selector;
    }

}