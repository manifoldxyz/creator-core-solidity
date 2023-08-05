// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";
import {ICreatorExtensionTokenURI} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {ERC721Extension} from "./ERC721Extension.sol";

contract ERC721TokenURIExtension is ICreatorExtensionTokenURI, ERC721Extension {
    string _uri;

    constructor(address creator) ERC721Extension(creator) {}

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    function setTokenURI(string calldata uri) public {
        _uri = uri;
    }

    function tokenURI(address, uint256) external view virtual override returns (string memory) {
        return _uri;
    }
}
