// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { BaseERC1155CreatorTest } from "../BaseERC1155CreatorTest.sol";
import { ERC1155Extension } from "../extensions/ERC1155Extension.sol";

contract ERC1155CreatorExtensionsTest is BaseERC1155CreatorTest {
    function testSupportsInterface() public {
        uint32[7] memory interfaceIds = [
            0x28f10a21, // ICreatorCoreV1
            0x5365e65c, // ICreatorCoreV2
            0x7d248440, // IERC1155CreatorCoreV1
            0xbb3bafd6, // Creator Core Royalties
            0x2a55205a, // EIP-2981 Royalties
            0xb7799584, // RaribleV1 Royalties
            0xd5a06d4c // Foundation Royalties
        ];
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            assertTrue(
                creatorContract().supportsInterface(bytes4(interfaceIds[i]))
            );
        }
    }

    function testExtensionRegistrationByOwner() public {
        _testExtensionRegistration(creator);
    }

    function testExtensionRegistrationByAdmin() public {
        // Approve an admin on the creator contract
        vm.prank(creator);
        creatorContract().approveAdmin(alice);
        _testExtensionRegistration(alice);
    }

    function _testExtensionRegistration(address account) private {
        // Default ERC1155Extension is already registered during test setUp
        vm.startPrank(account);

        // Revert on registering an EOA
        vm.expectRevert("Invalid");
        creatorContract().registerExtension(alice, "");

        // Revert on registering the creator contract
        vm.expectRevert("Invalid");
        creatorContract().registerExtension(creatorContractAddress, "");

        // Deploy a new ERC1155Extension
        address extension = address(
            new ERC1155Extension(creatorContractAddress)
        );
        assertEq(creatorContract().getExtensions().length, 0);

        // Register the ERC1155Extension
        creatorContract().registerExtension(extension, "");
        assertEq(creatorContract().getExtensions().length, 1);

        // Unregister the ERC1155Extension
        creatorContract().unregisterExtension(extension);
        assertEq(creatorContract().getExtensions().length, 0);

        vm.stopPrank();
    }

    function testExtensionBlacklist() public {
        // Revert on blacklisting self
        vm.prank(creator);
        vm.expectRevert("Cannot blacklist yourself");
        creatorContract().blacklistExtension(creatorContractAddress);

        // Deploy a new ERC1155Extension
        address extension = address(
            new ERC1155Extension(creatorContractAddress)
        );

        // Blacklist the ERC1155Extension
        vm.prank(creator);
        creatorContract().blacklistExtension(extension);

        // Can't register a blacklisted ERC1155Extension
        vm.expectRevert("Extension blacklisted");
        vm.prank(creator);
        creatorContract().registerExtension(extension, extensionTokenURI);
    }

    function testExtensionBlacklistRemovesRegistration() public {
        // Deploy a new ERC1155Extension
        address extension = address(
            new ERC1155Extension(creatorContractAddress)
        );

        // Register the ERC1155Extension
        vm.prank(creator);
        creatorContract().registerExtension(extension, extensionTokenURI);
        assertEq(creatorContract().getExtensions().length, 1);

        // Mint a token
        uint256 tokenId = mintWithExtension(extension, alice);

        // Blacklist the ERC1155Extension
        vm.prank(creator);
        creatorContract().blacklistExtension(extension);
        assertEq(creatorContract().getExtensions().length, 0);

        // Check token is no longer valid
        vm.expectRevert("Extension blacklisted");
        creatorContract().uri(tokenId);

        vm.expectRevert("Extension blacklisted");
        creatorContract().tokenExtension(tokenId);
    }
}
