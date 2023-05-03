// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../contracts/ERC721CreatorImplementation.sol";

contract DeployERC721CreatorImplementation is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        new ERC721CreatorImplementation{salt: 0x45524337323143726561746f72496d706c656d656e746174696f6e4552433732}();
        vm.stopBroadcast();
    }
}