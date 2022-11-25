// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../core/IERC1155CreatorCore.sol";
import "../extensions/ERC1155/ERC1155CreatorExtensionApproveTransfer.sol";
import "../extensions/ICreatorExtensionTokenURI.sol";
import "../extensions/CreatorExtensionRoyalties.sol";

contract MockERC1155CreatorExtensionOverride is ERC1155CreatorExtensionApproveTransfer, ICreatorExtensionTokenURI, CreatorExtensionRoyalties {

    bool _approveEnabled;
    string _tokenURI;
    address _creator;
    mapping(uint256 => RoyaltyInfo) _royaltyInfo;

    struct RoyaltyInfo {
        address payable[] recipients;
        uint256[] values;
    }

    constructor(address creator) {
        _creator = creator;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155CreatorExtensionApproveTransfer, CreatorExtensionRoyalties, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function testMintNew(address[] calldata to, uint256[] calldata amounts, string[] calldata uris) external {
        IERC1155CreatorCore(_creator).mintExtensionNew(to, amounts, uris);
    }

    function setApproveEnabled(bool enabled) public {
        _approveEnabled = enabled;
    }

    function setTokenURI(string calldata uri) public {
        _tokenURI = uri;
    }

    function approveTransfer(address, address, address, uint256[] calldata, uint256[] calldata) external view virtual override returns (bool) {
       return _approveEnabled;
    }

    function tokenURI(address creator, uint256) external view virtual override returns (string memory) {
        require(creator == _creator, "Invalid");
        return _tokenURI;
    }

    function setRoyaltyOverrides(uint256 tokenId, address payable[] memory receivers, uint256[] memory values) public {
        _royaltyInfo[tokenId] = RoyaltyInfo(receivers, values);
    }

    function getRoyalties(address creator, uint256 tokenId) external override view returns (address payable[] memory, uint256[] memory) {
        require(creator == _creator, "Invalid");

        if (_royaltyInfo[tokenId].recipients.length > 0) {
            RoyaltyInfo memory info = _royaltyInfo[tokenId];
            return (info.recipients, info.values);
        } else {
            return (new address payable[](0), new uint256[](0));
        }
    }
}
