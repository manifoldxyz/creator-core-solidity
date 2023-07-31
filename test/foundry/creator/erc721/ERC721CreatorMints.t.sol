// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721CreatorTest } from "../ERC721CreatorTest.sol";
import { Strings } from "openzeppelin/utils/Strings.sol";
import { ERC721Extension } from "./helpers/ERC721Extension.sol";

contract ERC721CreatorMintsTest is ERC721CreatorTest {
    ERC721Extension public extension;

    modifier withExtension() {
        vm.prank(creator);
        extension = new ERC721Extension(address(creatorContract));
        vm.prank(creator);
        creatorContract.registerExtension(
            address(extension),
            extensionTokenURI
        );
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
        // Mint a batch of tokens without an override URI
        mintBatchWithCreator(alice, 5);
    }

    function testMintBatchWithOverrideURI() public withExtension {
        // Mint a batch of tokens with an override URI
        string[] memory overrideURIs = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            overrideURIs[i] = string(
                abi.encodePacked("override://", Strings.toString(i))
            );
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
        // Mint a batch of tokens without an override URI
        mintBatchWithExtension(address(extension), alice, 5);
    }

    function testMintBatchWithExtensionAndOverrideURI() public withExtension {
        // Mint a batch of tokens with an override URI
        string[] memory overrideURIs = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            overrideURIs[i] = string(
                abi.encodePacked("override://", Strings.toString(i))
            );
        }
        mintBatchWithExtension(address(extension), alice, overrideURIs);
    }
}
