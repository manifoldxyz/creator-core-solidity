// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC721CreatorEnumerable } from "creator-core/ERC721CreatorEnumerable.sol";
import { ERC721CreatorBurnsTest } from "./erc721/mixins/ERC721CreatorBurns.sol";
import { ERC721CreatorExtensionsTest } from "./erc721/mixins/ERC721CreatorExtensions.sol";
import { ERC721CreatorMetadataTest } from "./erc721/mixins/ERC721CreatorMetadata.sol";
import { ERC721CreatorPermissionsTest } from "./erc721/mixins/ERC721CreatorPermissions.sol";
import { ERC721CreatorRoyaltiesTest } from "./erc721/mixins/ERC721CreatorRoyalties.sol";
import { ERC721CreatorTransfersTest } from "./erc721/mixins/ERC721CreatorTransfers.sol";

contract ERC721CreatorEnumerableTest is ERC721CreatorBurnsTest, ERC721CreatorExtensionsTest, ERC721CreatorMetadataTest, ERC721CreatorPermissionsTest, ERC721CreatorRoyaltiesTest, ERC721CreatorTransfersTest {
    function setUp() public virtual override {
        // Deploy creator contract
        vm.prank(creator);
        creatorContractAddress = address(new ERC721CreatorEnumerable("Test", "TEST"));

        // Set base token URI
        vm.prank(creator);
        creatorContract().setBaseTokenURI(baseTokenURI);
    }
}
