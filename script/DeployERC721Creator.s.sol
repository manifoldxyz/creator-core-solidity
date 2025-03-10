// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/ERC721Creator.sol";

contract DeployERC721Creator is Script {
    function run() external {
        vm.startBroadcast();
        new ERC721Creator{salt: 0x45524337323143726561746f72496d706c656d656e746174696f6e4552433732}("enm-test", "testenm");
        vm.stopBroadcast();
    }
}
