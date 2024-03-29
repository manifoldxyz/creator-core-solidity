// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {BaseERC1155CreatorTest} from "../BaseERC1155CreatorTest.sol";
import {ERC1155TokenURIExtension} from "../extensions/ERC1155TokenURIExtension.sol";

contract ERC1155CreatorMetadataTest is BaseERC1155CreatorTest {
    ERC1155TokenURIExtension public tokenURIExtension;

    modifier withTokenURIExtension() {
        vm.prank(creator);
        tokenURIExtension = new ERC1155TokenURIExtension(
            creatorContractAddress
        );
        vm.prank(creator);
        creatorContract().registerExtension(address(tokenURIExtension), extensionTokenURI);
        _;
    }

    function testTokenURIInvalidInput() public withTokenURIExtension {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        string[] memory uris = new string[](1);
        uris[0] = "override://";

        // Revert on invalid token ID
        vm.prank(creator);
        vm.expectRevert("Invalid token");
        creatorContract().setTokenURI(1, "override://");

        // Revert on invalid token input
        vm.prank(creator);
        vm.expectRevert("Invalid input");
        creatorContract().setTokenURI(new uint256[](0), uris);

        // Revert on invalid URI input
        vm.prank(creator);
        vm.expectRevert("Invalid input");
        creatorContract().setTokenURI(tokenIds, new string[](0));

        // Correct input allows setting token URI
        mintWithCreator(alice);
        vm.prank(creator);
        creatorContract().setTokenURI(tokenIds, uris);
        assertEq(creatorContract().uri(1), uris[0]);
    }

    function testTokenURINotRemovedWhenExtensionUnregistered() public withTokenURIExtension {
        // Mint a token
        uint256 tokenId = mintWithExtension(address(tokenURIExtension), alice);
        string memory tokenURI = creatorContract().uri(tokenId);

        // Unregister extension
        vm.prank(creator);
        creatorContract().unregisterExtension(address(tokenURIExtension));

        // Validate token URI is still set
        assertEq(creatorContract().uri(tokenId), tokenURI);
    }

    function testTokenURIExtensionUnique() public withTokenURIExtension {
        string memory tokenURI = "override://";

        // Mint a token via extension
        uint256 tokenId = mintWithExtension(address(tokenURIExtension), alice);

        // Mint a token via creator contract
        uint256 tokenId2 = mintWithCreator(alice);

        // Mint batch of tokens via extension
        uint256 tokenId3 = mintWithExtension(address(tokenURIExtension), alice, 10);

        // Update tokenURI to an override
        vm.prank(creator);
        tokenURIExtension.setTokenURI(tokenURI);

        // Validate extension tokens have updated URI
        assertEq(creatorContract().uri(tokenId), tokenURI);
        assertEq(creatorContract().uri(tokenId3), tokenURI);

        // Validate normal token has correct URI
        assertEq(creatorContract().uri(tokenId2), _uri(baseTokenURI, tokenId2));
    }

    function testTokenURIExtension() public withTokenURIExtension {
        string memory tokenURI = "override://";

        // Mint a token
        uint256 tokenId = mintWithExtension(address(tokenURIExtension), alice);

        // Returns no tokenURI
        assertEq(creatorContract().uri(tokenId), "");

        // Set token URI
        vm.prank(creator);
        tokenURIExtension.setTokenURI(tokenURI);

        // Returns correct token URI
        assertEq(creatorContract().uri(tokenId), tokenURI);
    }
}
