// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseCreatorTest } from "./BaseCreatorTest.sol";
import { ERC721Creator } from "creator-core/ERC721Creator.sol";
import {
    ICreatorExtensionTokenURI
} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import { IERC721Extension } from "./erc721/ERC721Extension.sol";
import {
    ERC165Checker
} from "openzeppelin/utils/introspection/ERC165Checker.sol";

contract ERC721CreatorTest is BaseCreatorTest {
    ERC721Creator creatorContract;

    function setUp() public virtual override {
        super.setUp();

        // Deploy creator contract
        vm.prank(creator);
        creatorContract = new ERC721Creator("Test", "TEST");

        // Set base token URI
        vm.prank(creator);
        creatorContract.setBaseTokenURI(baseTokenURI);
    }

    /**
     * @dev Mint helpers
     */

    function mintWithCreator(address to) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = creatorContract.mintBase(to);

        // Assert mint was successful
        assertMintWithCreator(tokenId, to, _uri(baseTokenURI, tokenId));

        return tokenId;
    }

    function mintWithCreator(
        address to,
        string memory uri
    ) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = creatorContract.mintBase(to, uri);

        // Assert mint was successful
        assertMintWithCreator(tokenId, to, uri);

        return tokenId;
    }

    function mintBatchWithCreator(
        address to,
        uint16 count
    ) internal returns (uint256[] memory) {
        // Mint a token
        vm.prank(creator);
        uint256[] memory tokenIds = creatorContract.mintBaseBatch(to, count);

        // Assert mints were successful
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertMintWithCreator(
                tokenIds[i],
                to,
                _uri(baseTokenURI, tokenIds[i])
            );
        }

        return tokenIds;
    }

    function mintBatchWithCreator(
        address to,
        string[] memory uris
    ) internal returns (uint256[] memory) {
        // Mint a token
        vm.prank(creator);
        uint256[] memory tokenIds = creatorContract.mintBaseBatch(to, uris);

        // Assert mints were successful
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertMintWithCreator(tokenIds[i], to, uris[i]);
        }

        return tokenIds;
    }

    function mintWithExtension(
        address extension,
        address to
    ) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = IERC721Extension(extension).mint(to);

        // If tokenId == 0, call reverted
        if (tokenId == 0) {
            return tokenId;
        }

        // Assert mint was successful
        assertMintWithExtension(
            extension,
            tokenId,
            to,
            _uri(extensionTokenURI, tokenId)
        );

        return tokenId;
    }

    function mintWithExtension(
        address extension,
        address to,
        string memory uri
    ) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = IERC721Extension(extension).mint(to, uri);

        // Assert mint was successful
        assertMintWithExtension(extension, tokenId, to, uri);

        return tokenId;
    }

    function mintBatchWithExtension(
        address extension,
        address to,
        uint16 count
    ) internal returns (uint256[] memory) {
        // Mint a token
        vm.prank(creator);
        uint256[] memory tokenIds = IERC721Extension(extension).mintBatch(
            to,
            count
        );

        // Assert mints were successful
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertMintWithExtension(
                extension,
                tokenIds[i],
                to,
                _uri(extensionTokenURI, tokenIds[i])
            );
        }

        return tokenIds;
    }

    function mintBatchWithExtension(
        address extension,
        address to,
        string[] memory uris
    ) internal returns (uint256[] memory) {
        // Mint a token
        vm.prank(creator);
        uint256[] memory tokenIds = IERC721Extension(extension).mintBatch(
            to,
            uris
        );

        // Assert mints were successful
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertMintWithExtension(extension, tokenIds[i], to, uris[i]);
        }

        return tokenIds;
    }

    function assertMintWithCreator(
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        // Validate mint was successful
        assertMint(tokenId, to, uri);

        // If mint via creator, validate no extension was registered
        vm.expectRevert();
        creatorContract.tokenExtension(tokenId);
    }

    function assertMintWithExtension(
        address extension,
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        // Update token  URI if needed
        if (
            ERC165Checker.supportsInterface(
                extension,
                type(ICreatorExtensionTokenURI).interfaceId
            )
        ) {
            // If extension overrides token URI, set that as expected
            uri = ICreatorExtensionTokenURI(extension).tokenURI(
                address(creatorContract),
                tokenId
            );
        }

        // Validate mint was successful
        assertMint(tokenId, to, uri);

        // Validate extension was registered during mint
        assertEq(creatorContract.tokenExtension(tokenId), extension);
    }

    function assertMint(
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        // Check balance change
        assertEq(creatorContract.ownerOf(tokenId), to);

        // Check token URI
        assertEq(creatorContract.tokenURI(tokenId), uri);
    }
}
