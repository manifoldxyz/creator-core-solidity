// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721CreatorTest } from "../ERC721CreatorTest.sol";
import { ERC721Extension } from "./helpers/ERC721Extension.sol";

contract ERC721CreatorExtensionsTest is ERC721CreatorTest {
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

    function testExtensionRegistrationByOwner() public {
        _testExtensionRegistration(creator);
    }

    function testExtensionRegistrationByAdmin() public {
        // Approve an admin on the creator contract
        vm.prank(creator);
        creatorContract.approveAdmin(alice);
        _testExtensionRegistration(alice);
    }

    function _testExtensionRegistration(address account) private {
        // Default ERC721Extension is already registered during test setUp
        vm.startPrank(account);

        // Revert on registering an EOA
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(alice, "");

        // Revert on registering the creator contract
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(address(creatorContract), "");

        // Deploy a new ERC721Extension
        address extension = address(
            new ERC721Extension(address(creatorContract))
        );
        assertEq(creatorContract.getExtensions().length, 0);

        // Register the ERC721Extension
        creatorContract.registerExtension(extension, "");
        assertEq(creatorContract.getExtensions().length, 1);

        // Unregister the ERC721Extension
        creatorContract.unregisterExtension(extension);
        assertEq(creatorContract.getExtensions().length, 0);

        vm.stopPrank();
    }

    function testExtensionBlacklist() public {
        // Revert on blacklisting self
        vm.prank(creator);
        vm.expectRevert("Cannot blacklist yourself");
        creatorContract.blacklistExtension(address(creatorContract));

        // Deploy a new ERC721Extension
        address extension = address(
            new ERC721Extension(address(creatorContract))
        );

        // Blacklist the ERC721Extension
        vm.prank(creator);
        creatorContract.blacklistExtension(extension);

        // Can't register a blacklisted ERC721Extension
        vm.expectRevert("Extension blacklisted");
        vm.prank(creator);
        creatorContract.registerExtension(extension, extensionTokenURI);
    }

    function testExtensionBlacklistRemovesRegistration() public {
        // Deploy a new ERC721Extension
        address extension = address(
            new ERC721Extension(address(creatorContract))
        );

        // Register the ERC721Extension
        vm.prank(creator);
        creatorContract.registerExtension(extension, extensionTokenURI);
        assertEq(creatorContract.getExtensions().length, 1);

        // Mint a token
        uint256 tokenId = mintWithExtension(extension, alice);

        // Blacklist the ERC721Extension
        vm.prank(creator);
        creatorContract.blacklistExtension(extension);
        assertEq(creatorContract.getExtensions().length, 0);

        // Check token is no longer valid
        vm.expectRevert("Extension blacklisted");
        creatorContract.tokenURI(tokenId);

        vm.expectRevert("Extension blacklisted");
        creatorContract.tokenExtension(tokenId);
    }
}
