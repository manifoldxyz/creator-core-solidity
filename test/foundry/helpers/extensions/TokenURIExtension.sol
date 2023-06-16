// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721CreatorCore} from "creator-core/core/IERC721CreatorCore.sol";
import {ICreatorExtensionTokenURI} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract TokenURIExtension is ICreatorExtensionTokenURI {
    address _creator;
    string _tokenURI;

    constructor(address creator) {
        _creator = creator;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool) {
        return
            interfaceId == type(ICreatorExtensionTokenURI).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function mint(address to) external {
        IERC721CreatorCore(_creator).mintExtension(to);
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
