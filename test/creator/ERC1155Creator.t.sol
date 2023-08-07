// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC1155CreatorBurnsTest} from "./erc1155/mixins/ERC1155CreatorBurns.sol";
import {ERC1155CreatorExtensionsTest} from "./erc1155/mixins/ERC1155CreatorExtensions.sol";
import {ERC1155CreatorMetadataTest} from "./erc1155/mixins/ERC1155CreatorMetadata.sol";
import {ERC1155CreatorPermissionsTest} from "./erc1155/mixins/ERC1155CreatorPermissions.sol";
import {ERC1155CreatorRoyaltiesTest} from "./erc1155/mixins/ERC1155CreatorRoyalties.sol";
import {ERC1155CreatorTransfersTest} from "./erc1155/mixins/ERC1155CreatorTransfers.sol";

contract ERC1155CreatorTest is
    ERC1155CreatorBurnsTest,
    ERC1155CreatorExtensionsTest,
    ERC1155CreatorMetadataTest,
    ERC1155CreatorPermissionsTest,
    ERC1155CreatorRoyaltiesTest,
    ERC1155CreatorTransfersTest
{}
