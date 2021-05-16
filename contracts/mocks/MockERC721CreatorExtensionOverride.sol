// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../core/IERC721CreatorCore.sol";
import "../extensions/ERC721CreatorExtensionApproveTransfer.sol";
import "../extensions/IERC721CreatorExtensionTokenURI.sol";

contract MockERC721CreatorExtensionOverride is ERC721CreatorExtensionApproveTransfer, IERC721CreatorExtensionTokenURI {

    bool _approveEnabled;
    string _tokenURI;
    address _creator;

    constructor(address creator) {
        _creator = creator;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721CreatorExtensionApproveTransfer, IERC165) returns (bool) {
        return interfaceId == type(IERC721CreatorExtensionTokenURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function testMint(address to) external {
        IERC721CreatorCore(_creator).mintExtension(to);
    }

    function setApproveEnabled(bool enabled) public {
        _approveEnabled = enabled;
    }

    function setTokenURI(string calldata uri) public {
        _tokenURI = uri;
    }

    function approveTransfer(address creator, address, address, uint256) external view virtual override returns (bool) {
        require(creator == _creator, "Invalid");
        return _approveEnabled;
    }

    function tokenURI(address creator, uint256) external view virtual override returns (string memory) {
        require(creator == _creator, "Invalid");
        return _tokenURI;
    }


}
