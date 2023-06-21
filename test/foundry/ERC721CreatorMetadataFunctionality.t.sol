// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC721CreatorTest} from "./helpers/ERC721CreatorTest.sol";
import {TokenURIExtension} from "./helpers/extensions/TokenURIExtension.sol";

contract ERC721CreatorMetadataFunctionalityTest is ERC721CreatorTest {
    TokenURIExtension tokenURIExtension;

    function setUp() public override {
        super.setUp();
        vm.prank(creator);
        tokenURIExtension = new TokenURIExtension(address(creatorContract));
        _registerExtension(address(tokenURIExtension));
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
