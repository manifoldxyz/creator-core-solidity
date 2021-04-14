// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/utils/introspection/ERC165.sol";
import "./INFT2ERC20RateEngine.sol";

abstract contract NFT2ERC20RateEngine is ERC165, INFT2ERC20RateEngine {
     /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(INFT2ERC20RateEngine).interfaceId
            || super.supportsInterface(interfaceId);
    }
}