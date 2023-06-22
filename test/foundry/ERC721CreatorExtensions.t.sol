// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {Extension} from "./helpers/extensions/Extension.sol";

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
        // Default extension is already registered during test setUp
        vm.startPrank(account);

        // Revert on registering an EOA
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(alice, "");

        // Revert on registering the creator contract
        vm.expectRevert("Invalid");
        creatorContract.registerExtension(address(creatorContract), "");

        // Deploy a new extension
        address extension = address(new Extension(address(creatorContract)));
        assertEq(creatorContract.getExtensions().length, 0);

        // Register the extension
        creatorContract.registerExtension(extension, "");
        assertEq(creatorContract.getExtensions().length, 1);

        // Unregister the extension
        creatorContract.unregisterExtension(extension);
        assertEq(creatorContract.getExtensions().length, 0);

        vm.stopPrank();
    }

    function testExtensionBlacklist() public {
        // Revert on blacklisting self
        vm.prank(creator);
        vm.expectRevert("Cannot blacklist yourself");
        creatorContract.blacklistExtension(address(creatorContract));

        // Deploy a new extension
        address extension = address(new Extension(address(creatorContract)));

        // Blacklist the extension
        vm.prank(creator);
        creatorContract.blacklistExtension(extension);

        // Can't register a blacklisted extension
        vm.expectRevert("Extension blacklisted");
        _registerExtension(extension);
    }

    function testExtensionBlacklistRemovesRegistration() public {
        // Deploy a new extension
        address extension = address(new Extension(address(creatorContract)));

        // Register the extension
        _registerExtension(extension);
        assertEq(creatorContract.getExtensions().length, 1);

        // Mint a token
        uint256 tokenId = mintWithExtension(extension, alice);

        // Blacklist the extension
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
