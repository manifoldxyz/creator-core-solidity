// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/ERC1155CreatorImplementation.sol";

contract DeployERC1155CreatorImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new ERC1155CreatorImplementation{salt: 0x4552433131353543726561746f72496d706c656d656e746174696f6e45524331}();
        vm.stopBroadcast();
    }
}