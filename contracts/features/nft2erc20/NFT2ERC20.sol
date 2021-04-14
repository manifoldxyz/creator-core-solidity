// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";

import "openzeppelin-solidity/contracts/token/ERC1155/ERC1155.sol";


import "./INFT2ERC20.sol";
import "./INFT2ERC20RateEngine.sol";
import "../../access/AdminControl.sol";

contract NFT2ERC20 is ReentrancyGuard, ERC20Burnable, AdminControl, INFT2ERC20 {

    address private _rateEngine;
    
    mapping (string => bytes4) private _specTransferFunction;

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    }

    event Swapped(address indexed account, address indexed tokenContract, uint256[] values, string spec, uint256 rate);
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AdminControl) returns (bool) {
        return interfaceId == type(INFT2ERC20).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {INFT2ERC20-setRateEngine}.
     */
    function setRateEngine(address rateEngine) external override adminRequired {
        require(ERC165Checker.supportsInterface(rateEngine, type(INFT2ERC20RateEngine).interfaceId), "NFT2ERC20: Must implement INFT2ERC20RateEngine");
        _rateEngine = rateEngine;
    }

    /**
     * @dev See {INFT2ERC20-setTransferFunction}.
     */
    function setTransferFunction(string calldata spec, bytes4 transferFunction) external override adminRequired {
        _specTransferFunction[spec] = transferFunction;
    }

    /**
     * @dev See {INFT2ERC20-burnToken}.
     */
    function burnToken(address tokenContract, uint256[] calldata values, string calldata spec) public override nonReentrant {
        require(values.length > 0, "NFT2ERC20: Must provide at least one value");
        require(_rateEngine != address(0), "NFT2ERC20: Rate Engine not configured");
        require(_specTransferFunction[spec] != bytes4(0x0), "NFT2ERC20: Transfer function not defined for spec");
        uint256 rate = INFT2ERC20RateEngine(_rateEngine).getRate(totalSupply(), tokenContract, values, spec);

        bytes memory byteValues = abi.encode(values[0]);
        if (values.length > 1) {
            // Encode value params and burn token
            for (uint i = 1; i < values.length; i++) {
                byteValues = abi.encodePacked(byteValues, values[i]);
            }
            (bool success, bytes memory returnData) = tokenContract.call(abi.encodePacked(_specTransferFunction[spec], uint256(uint160(msg.sender)), uint256(0xdEaD), byteValues));
            //(bool success, bytes memory returnData) = tokenContract.call(abi.encodeWithSelector(_specTransferFunction[spec], msg.sender, address(0xdEaD), values[0], values[1], bytes("")));
            //ERC1155(tokenContract).safeTransferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, values[0], values[1], "");

            require(success, "NFT2ERC20: Burn failure");
        } else {
            // Burn the token
            (bool success, bytes memory returnData) = tokenContract.call(abi.encodeWithSelector(_specTransferFunction[spec], msg.sender, address(0xdEaD), values[0]));
            require(success, "NFT2ERC20: Burn failure");
        }
        
        _mint(msg.sender, rate);

        emit Swapped(msg.sender, tokenContract, values, spec, rate);
    }

    
}