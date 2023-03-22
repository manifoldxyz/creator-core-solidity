// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../core/IERC721CreatorCore.sol";
import "../extensions/ICreatorExtensionTokenURI.sol";

contract MockERC721CreatorExtensionUniqueURI is ERC165, ICreatorExtensionTokenURI {
    using Strings for uint256;

    string _tokenURI;
    address _creator;
    uint80 _mintCount;
    mapping(uint256 => RoyaltyInfo) _royaltyInfo;

    struct RoyaltyInfo {
        address payable[] recipients;
        uint256[] values;
    }

    constructor(address creator, uint80 startIndex) {
        _creator = creator;
        _mintCount = startIndex;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(ICreatorExtensionTokenURI).interfaceId || super.supportsInterface(interfaceId);
    }

    function testMint(address to) external {
        _mintCount++;
        IERC721CreatorCore(_creator).mintExtension(to, _mintCount);
    }

    function testMintBatch(address to, uint16 count) external {
        uint80[] memory data = new uint80[](count);
        for (uint i = 0; i < count;) {
            data[i] = uint80(_mintCount + 1 + i);
            unchecked { ++i; }
        }
        _mintCount += count;
        IERC721CreatorCore(_creator).mintExtensionBatch(to, data);
    }

    function setTokenURI(string calldata uri) public {
        _tokenURI = uri;
    }

    function tokenURI(address creator, uint256 tokenId) external view virtual override returns (string memory) {
        require(creator == _creator, "Invalid");
        uint80 data = IERC721CreatorCore(creator).tokenData(tokenId);
        return string(abi.encodePacked(_tokenURI, '/', uint256(data).toString()));
    }

}
