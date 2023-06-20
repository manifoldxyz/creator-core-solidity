// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {BurnableExtension} from "./helpers/extensions/BurnableExtension.sol";

contract ERC721CreatorCoreFunctionalityTest is ERC721CreatorTest {
    function testSupportsInterface() public {
        uint32[8] memory interfaceIds = [
            0x28f10a21, // ICreatorCoreV1
            0x5365e65c, // ICreatorCoreV2
            0x9088c207, // IERC721CreatorCoreV1
            0xb5d2729f, // IERC721CreatorCoreV2
            0xbb3bafd6, // Creator Core Royalties
            0x2a55205a, // EIP-2981 Royalties
            0xb7799584, // RaribleV1 Royalties
            0xd5a06d4c // Foundation Royalties
        ];
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            assertTrue(
                creatorContract.supportsInterface(bytes4(interfaceIds[i]))
            );
        }
    }

    function testInvalidExtensionOverride() public {
        // Extension is not a contract
        vm.prank(creator);
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(alice, "");

        // Creator contract can't register itself
        vm.prank(creator);
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(address(creatorContract), "");
    }

    function testExtensionRegistration() public {
        assertEq(creatorContract.getExtensions().length, 0);

        // Creator can register an extension
        vm.startPrank(creator);
        address extension1 = address(
            new BurnableExtension(address(creatorContract))
        );
        creatorContract.registerExtension(extension1, "extension1");
        vm.stopPrank();

        assertEq(creatorContract.getExtensions().length, 1);

        // Approve an admin on the creator contract
        vm.prank(creator);
        creatorContract.approveAdmin(alice);

        // Admin can register an extension
        vm.startPrank(alice);
        address extension2 = address(
            new BurnableExtension(address(creatorContract))
        );
        creatorContract.registerExtension(extension2, "extension2");
        vm.stopPrank();

        assertEq(creatorContract.getExtensions().length, 2);
    }

    function testMint() public {
        // Mint a token without an override URI
        mintWithCreator(alice);

        // Mint a token with an override URI
        mintWithCreator(alice, "ar://");
    }

    function testExtensionMint() public withTokenURIExtension {
        // Check tokenExtension is registered on mint
        uint256 tokenId = tokenURIExtension.mint(alice);
        assertEq(
            creatorContract.tokenExtension(tokenId),
            address(tokenURIExtension)
        );
    }
}
