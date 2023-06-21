// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC721Creator} from "creator-core/ERC721Creator.sol";
import {ICreatorExtensionTokenURI} from "creator-core/extensions/ICreatorExtensionTokenURI.sol";
import {MintableExtension, IMintableExtension} from "./extensions/MintableExtension.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC165Checker} from "openzeppelin/utils/introspection/ERC165Checker.sol";

contract ERC721CreatorTest is Test {
    ERC721Creator creatorContract;
    MintableExtension mintableExtension;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address creator = address(0xC12EA7012);

    string baseTokenURI = "creator://";
    string extensionTokenURI = "extension://";

    function setUp() public virtual {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(creator, "creator");
        _setUpCreatorContract();
    }

    function _setUpCreatorContract() private {
        // Deploy creator contract
        vm.prank(creator);
        creatorContract = new ERC721Creator("Test", "TEST");

        // Set base token URI
        vm.prank(creator);
        creatorContract.setBaseTokenURI(baseTokenURI);

        // Register mintable extension
        vm.prank(creator);
        mintableExtension = new MintableExtension(address(creatorContract));
        _registerExtension(address(mintableExtension));
    }

    /**
     * @dev Extension helpers
     */

    function _registerExtension(address extension) internal {
        vm.prank(creator);
        creatorContract.registerExtension(extension, extensionTokenURI);
    }

    /**
     * @dev Mint helpers
     */

    function mintWithCreator(address to) internal returns (uint256) {
        // Mint a token
        vm.prank(creator);
        uint256 tokenId = creatorContract.mintBase(to);

        // Assert mint was successful
        assertMintWithCreator(tokenId, to, _tokenURI(baseTokenURI, tokenId));

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
                _tokenURI(baseTokenURI, tokenIds[i])
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
        uint256 tokenId = IMintableExtension(extension).mint(to);

        // Assert mint was successful
        assertMintWithExtension(
            extension,
            tokenId,
            to,
            _tokenURI(extensionTokenURI, tokenId)
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
        uint256 tokenId = IMintableExtension(extension).mint(to, uri);

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
        uint256[] memory tokenIds = IMintableExtension(extension).mintBatch(
            to,
            count
        );

        // Assert mints were successful
        for (uint256 i = 0; i < tokenIds.length; i++) {
            assertMintWithExtension(
                extension,
                tokenIds[i],
                to,
                _tokenURI(extensionTokenURI, tokenIds[i])
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
        uint256[] memory tokenIds = IMintableExtension(extension).mintBatch(
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
        assertMintWithExtension(address(0), tokenId, to, uri);
    }

    function assertMintWithExtension(
        address extension,
        uint256 tokenId,
        address to,
        string memory uri
    ) internal {
        // Check balance change
        assertEq(creatorContract.ownerOf(tokenId), to);

        // Check token URI
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
        assertEq(creatorContract.tokenURI(tokenId), uri);

        // Check extension registration
        if (extension == address(0)) {
            // If mint via creator, validate no extension was registered
            vm.expectRevert();
            creatorContract.tokenExtension(tokenId);
        } else {
            // Otherwise, validate extension was registered during mint
            assertEq(creatorContract.tokenExtension(tokenId), extension);
        }
    }

    function _tokenURI(
        string memory uri,
        uint256 tokenId
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(uri, Strings.toString(tokenId)));
    }
}
