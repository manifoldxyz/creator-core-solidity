// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155CreatorCore } from "creator-core/core/IERC1155CreatorCore.sol";
import {
    ICreatorExtensionTokenURI
} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import {
    IERC165
} from "openzeppelin/utils/introspection/IERC165.sol";
import { ERC1155Extension } from "./ERC1155Extension.sol";

contract ERC1155TokenURIExtension is
    ICreatorExtensionTokenURI,
    ERC1155Extension
{
    string _uri;

    constructor(address creator) ERC1155Extension(creator) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function setTokenURI(string calldata uri) public {
        _uri = uri;
    }

    function tokenURI(
        address,
        uint256
    ) external view virtual override returns (string memory) {
        return _uri;
    }
}
