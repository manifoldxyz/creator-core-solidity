// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import {MintableExtension} from "./helpers/extensions/MintableExtension.sol";

contract ERC721CreatorMintFunctionalityTest is ERC721CreatorTest {
    MintableExtension mintableExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        mintableExtension = new MintableExtension(address(creatorContract));
        _registerExtension(address(mintableExtension));
    }

    function testMint() public {
        // Mint a token without an override URI
        mintWithCreator(alice);
    }

    function testMintWithOverrideURI() public {
        // Mint a token with an override URI
        mintWithCreator(alice, "override://");
    }

    function testMintBatch() public {
        // Mint a batch of tokens without an override URI
        mintBatchWithCreator(alice, 5);
    }

    function testMintBatchWithOverrideURI() public {
        // Mint a batch of tokens with an override URI
        string[] memory overrideURIs = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            overrideURIs[i] = string(
                abi.encodePacked("override://", Strings.toString(i))
            );
        }
        mintBatchWithCreator(alice, overrideURIs);
    }

    function testMintWithExtension() public {
        // Mint a token without an override URI
        mintWithExtension(address(mintableExtension), alice);
    }

    function testMintWithExtensionAndOverrideURI() public {
        // Mint a token with an override URI
        mintWithExtension(address(mintableExtension), alice, "override://");
    }

    function testMintBatchWithExtension() public {
        // Mint a batch of tokens without an override URI
        mintBatchWithExtension(address(mintableExtension), alice, 5);
    }

    function testMintBatchWithExtensionAndOverrideURI() public {
        // Mint a batch of tokens with an override URI
        string[] memory overrideURIs = new string[](5);
        for (uint256 i = 0; i < 5; i++) {
            overrideURIs[i] = string(
                abi.encodePacked("override://", Strings.toString(i))
            );
        }
        mintBatchWithExtension(address(mintableExtension), alice, overrideURIs);
    }
}
