// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {BaseERC1155CreatorTest} from "../BaseERC1155CreatorTest.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {ERC1155Extension} from "../extensions/ERC1155Extension.sol";

contract ERC1155CreatorMintsTest is BaseERC1155CreatorTest {
    ERC1155Extension extension;

    modifier withExtension() {
        vm.prank(creator);
        extension = new ERC1155Extension(creatorContractAddress);
        vm.prank(creator);
        creatorContract().registerExtension(address(extension), extensionTokenURI);
        _;
    }

    function testMint() public withExtension {
        // Mint a token without an override URI
        mintWithCreator(alice);
    }

    function testMintWithOverrideURI() public withExtension {
        // Mint a token with an override URI
        mintWithCreator(alice, "override://");
    }

    function testMintBatch() public withExtension {
        mintWithCreator(_addresses(alice), _uint256s(100, 200), _strings("", "t1"));

        mintWithCreator(_addresses(alice, bob), _uint256s(100), new string[](0));

        mintWithCreator(_addresses(alice, bob), _uint256s(100, 200), _strings("t2"));

        vm.expectRevert("Invalid input");
        mintWithCreator(_addresses(alice, bob), _uint256s(100), _strings("", ""));

        vm.expectRevert("Invalid input");
        mintWithCreator(_addresses(alice, bob), _uint256s(100, 200, 300), new string[](0));
    }

    function testMintBatchWithOverrideURI() public withExtension {
        // Mint a batch of tokens with an override URI
        string[] memory overrideURIs = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            overrideURIs[i] = string(abi.encodePacked("override://", Strings.toString(i)));
        }
        mintBatchWithCreator(alice, overrideURIs);
    }

    function testMintWithExtension() public withExtension {
        // Mint a token without an override URI
        mintWithExtension(address(extension), alice);
    }

    function testMintWithExtensionAndOverrideURI() public withExtension {
        // Mint a token with an override URI
        mintWithExtension(address(extension), alice, "override://");
    }

    function testMintBatchWithExtension() public withExtension {
        mintWithExtension(address(extension), _addresses(alice), _uint256s(100, 200), _strings("", "t1"));

        mintWithExtension(address(extension), _addresses(alice, bob), _uint256s(100), new string[](0));

        mintWithExtension(address(extension), _addresses(alice, bob), _uint256s(100, 200), _strings("t2"));

        vm.expectRevert("Invalid input");
        mintWithExtension(address(extension), _addresses(alice, bob), _uint256s(100), _strings("", ""));

        vm.expectRevert("Invalid input");
        mintWithExtension(address(extension), _addresses(alice, bob), _uint256s(100, 200, 300), new string[](0));
    }

    function testMintBatchWithExtensionAndOverrideURI() public withExtension {
        // Mint a batch of tokens with an override URI
        string[] memory overrideURIs = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            overrideURIs[i] = string(abi.encodePacked("override://", Strings.toString(i)));
        }
        mintBatchWithExtension(address(extension), alice, overrideURIs);
    }

    function testMintExisting() public withExtension {
        // Mint some tokens
        uint256 tokenId1 = mintWithCreator(alice, 1);
        uint256 tokenId2 = mintWithCreator(alice, 10);

        // Verify can't use extension to mint token
        vm.prank(creator);
        vm.expectRevert("Token not created by this extension");
        extension.mintExisting(_addresses(alice), _uint256s(tokenId1), _uint256s(1));

        // Mint additional tokenId1
        vm.prank(creator);
        creatorContract().mintBaseExisting(_addresses(alice), _uint256s(tokenId1), _uint256s(1));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 2);

        // Mint additional tokenId1 and tokenId2 at the same time
        vm.prank(creator);
        creatorContract().mintBaseExisting(_addresses(alice), _uint256s(tokenId1, tokenId2), _uint256s(1, 10));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 3);
        assertEq(creatorContract().balanceOf(alice, tokenId2), 20);

        // Mint additional same amount of tokenId1 to two recipients
        vm.prank(creator);
        creatorContract().mintBaseExisting(_addresses(alice, bob), _uint256s(tokenId1), _uint256s(1));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 4);
        assertEq(creatorContract().balanceOf(bob, tokenId1), 1);

        // Mint additional different amount of tokenId1 to two recipients
        vm.prank(creator);
        creatorContract().mintBaseExisting(_addresses(alice, bob), _uint256s(tokenId1), _uint256s(1, 2));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 5);
        assertEq(creatorContract().balanceOf(bob, tokenId1), 3);

        // Mint additional different amount of tokenId1 and tokenId2 to two recipients
        vm.prank(creator);
        creatorContract().mintBaseExisting(_addresses(alice, bob), _uint256s(tokenId1, tokenId2), _uint256s(1, 20));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 6);
        assertEq(creatorContract().balanceOf(bob, tokenId2), 20);
    }

    function testMintExistingWithExtension() public withExtension {
        // Mint some tokens
        uint256 tokenId1 = mintWithExtension(address(extension), alice, 1);
        uint256 tokenId2 = mintWithExtension(address(extension), alice, 10);

        // Verify can't mint extension tokens directly
        vm.prank(creator);
        vm.expectRevert("Token created by extension");
        creatorContract().mintBaseExisting(_addresses(alice), _uint256s(tokenId1), _uint256s(1));

        // Mint additional tokenId1
        vm.prank(creator);
        extension.mintExisting(_addresses(alice), _uint256s(tokenId1), _uint256s(1));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 2);

        // Mint additional tokenId1 and tokenId2 at the same time
        vm.prank(creator);
        extension.mintExisting(_addresses(alice), _uint256s(tokenId1, tokenId2), _uint256s(1, 10));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 3);
        assertEq(creatorContract().balanceOf(alice, tokenId2), 20);

        // Mint additional same amount of tokenId1 to two recipients
        vm.prank(creator);
        extension.mintExisting(_addresses(alice, bob), _uint256s(tokenId1), _uint256s(1));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 4);
        assertEq(creatorContract().balanceOf(bob, tokenId1), 1);

        // Mint additional different amount of tokenId1 to two recipients
        vm.prank(creator);
        extension.mintExisting(_addresses(alice, bob), _uint256s(tokenId1), _uint256s(1, 2));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 5);
        assertEq(creatorContract().balanceOf(bob, tokenId1), 3);

        // Mint additional different amount of tokenId1 and tokenId2 to two recipients
        vm.prank(creator);
        extension.mintExisting(_addresses(alice, bob), _uint256s(tokenId1, tokenId2), _uint256s(1, 20));
        assertEq(creatorContract().balanceOf(alice, tokenId1), 6);
        assertEq(creatorContract().balanceOf(bob, tokenId2), 20);
    }

    function _addresses(address a1) internal pure returns (address[] memory) {
        address[] memory addresses = new address[](1);
        addresses[0] = a1;
        return addresses;
    }

    function _addresses(address a1, address a2) internal pure returns (address[] memory) {
        address[] memory addresses = new address[](2);
        addresses[0] = a1;
        addresses[1] = a2;
        return addresses;
    }

    function _uint256s(uint256 a1) internal pure returns (uint256[] memory) {
        uint256[] memory uint256s = new uint256[](1);
        uint256s[0] = a1;
        return uint256s;
    }

    function _uint256s(uint256 a1, uint256 a2) internal pure returns (uint256[] memory) {
        uint256[] memory uint256s = new uint256[](2);
        uint256s[0] = a1;
        uint256s[1] = a2;
        return uint256s;
    }

    function _uint256s(uint256 a1, uint256 a2, uint256 a3) internal pure returns (uint256[] memory) {
        uint256[] memory uint256s = new uint256[](3);
        uint256s[0] = a1;
        uint256s[1] = a2;
        uint256s[2] = a3;
        return uint256s;
    }

    function _strings(string memory a1) internal pure returns (string[] memory) {
        string[] memory strings = new string[](1);
        strings[0] = a1;
        return strings;
    }

    function _strings(string memory a1, string memory a2) internal pure returns (string[] memory) {
        string[] memory strings = new string[](2);
        strings[0] = a1;
        strings[1] = a2;
        return strings;
    }
}
