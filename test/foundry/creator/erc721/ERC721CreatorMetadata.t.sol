// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721CreatorTest } from "../ERC721CreatorTest.sol";
import {
    ERC721TokenURIExtension
} from "./helpers/ERC721TokenURIExtension.sol";

contract ERC721CreatorMetadataTest is ERC721CreatorTest {
    ERC721TokenURIExtension tokenURIExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        tokenURIExtension = new ERC721TokenURIExtension(
            address(creatorContract)
        );
        vm.prank(creator);
        creatorContract.registerExtension(
            address(tokenURIExtension),
            extensionTokenURI
        );
    }

    function testTokenURIInvalidInput() public {
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = 1;

        string[] memory uris = new string[](1);
        uris[0] = "override://";

        // Revert on invalid token ID
        vm.prank(creator);
        vm.expectRevert("Invalid token");
        creatorContract.setTokenURI(1, "override://");

        // Revert on invalid token input
        vm.prank(creator);
        vm.expectRevert("Invalid input");
        creatorContract.setTokenURI(new uint256[](0), uris);

        // Revert on invalid URI input
        vm.prank(creator);
        vm.expectRevert("Invalid input");
        creatorContract.setTokenURI(tokenIds, new string[](0));

        // Correct input allows setting token URI
        mintWithCreator(alice);
        vm.prank(creator);
        creatorContract.setTokenURI(tokenIds, uris);
        assertEq(creatorContract.tokenURI(1), uris[0]);
    }

    function testTokenURINotRemovedWhenExtensionUnregistered() public {
        // Mint a token
        uint256 tokenId = mintWithExtension(address(tokenURIExtension), alice);
        string memory tokenURI = creatorContract.tokenURI(tokenId);

        // Unregister extension
        vm.prank(creator);
        creatorContract.unregisterExtension(address(tokenURIExtension));

        // Validate token URI is still set
        assertEq(creatorContract.tokenURI(tokenId), tokenURI);
    }

    function testTokenURIExtensionUnique() public {
        string memory tokenURI = "override://";

        // Mint a token via extension
        uint256 tokenId = mintWithExtension(address(tokenURIExtension), alice);

        // Mint a token via creator contract
        uint256 tokenId2 = mintWithCreator(alice);

        // Mint batch of tokens via extension
        uint256[] memory tokenIds = mintBatchWithExtension(
            address(tokenURIExtension),
            alice,
            10
        );

        // Update tokenURI to an override
        vm.prank(creator);
        tokenURIExtension.setTokenURI(tokenURI);

        // Validate extension tokens have updated URI
        assertEq(creatorContract.tokenURI(tokenId), tokenURI);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertEq(creatorContract.tokenURI(tokenIds[i]), tokenURI);
        }

        // Validate normal token has correct URI
        assertEq(
            creatorContract.tokenURI(tokenId2),
            _uri(baseTokenURI, tokenId2)
        );
    }

    function testTokenURIExtension() public {
        string memory tokenURI = "override://";

        // Mint a token
        uint256 tokenId = mintWithExtension(address(tokenURIExtension), alice);

        // Returns no tokenURI
        assertEq(creatorContract.tokenURI(tokenId), "");

        // Set token URI
        vm.prank(creator);
        tokenURIExtension.setTokenURI(tokenURI);

        // Returns correct token URI
        assertEq(creatorContract.tokenURI(tokenId), tokenURI);
    }
}
