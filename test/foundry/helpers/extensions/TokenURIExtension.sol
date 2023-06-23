// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC721CreatorCore } from "creator-core/core/IERC721CreatorCore.sol";
import {
    ICreatorExtensionTokenURI
} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import {
    IERC165
} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { Extension } from "./Extension.sol";

contract TokenURIExtension is ICreatorExtensionTokenURI, Extension {
    string _tokenURI;

    constructor(address creator) Extension(creator) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function setTokenURI(string calldata uri) public {
        _tokenURI = uri;
    }

    function tokenURI(
        address,
        uint256
    ) external view virtual override returns (string memory) {
        return _tokenURI;
    }
}
