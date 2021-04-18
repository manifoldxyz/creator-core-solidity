// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz

import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/introspection/ERC165Checker.sol";

import "./INFT2ERC20.sol";
import "./INFT2ERC20RateEngine.sol";
import "../../access/AdminControl.sol";

contract NFT2ERC20 is ReentrancyGuard, ERC20Burnable, AdminControl, INFT2ERC20 {

    address private _rateEngine;
    address private _treasury;
    uint128 private _treasuryBasisPoints;
    
    mapping (string => bytes4) private _specTransferFunction;

    constructor (string memory _name, string memory _symbol) ERC20(_name, _symbol) {
    }

    event Swapped(address indexed account, address indexed tokenContract, uint256[] args, string spec, uint256 rate);
    
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
        require(ERC165Checker.supportsInterface(rateEngine, type(INFT2ERC20RateEngine).interfaceId), "Must implement INFT2ERC20RateEngine");
        _rateEngine = rateEngine;
    }

    /*
     * @dev See {INFT2ERC20-setTreasury}
     */
    function setTreasury(address treasury, uint128 basisPoints) external override adminRequired {
        require(basisPoints < 10000, "basisPoints must be less than 10000 (100%)");
        _treasury = treasury;
        _treasuryBasisPoints = basisPoints;
    }

    /*
     * @dev See {INFT2ERC20-getTreasury}
     */
    function getTreasury() external view override returns (address, uint128) {
        return (_treasury, _treasuryBasisPoints);
    }

    /**
     * @dev See {INFT2ERC20-getRateEngine}.
     */
    function getRateEngine() external view override returns (address) {
        return _rateEngine;
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
    function burnToken(address tokenContract, uint256[] calldata args, string calldata spec) public override nonReentrant {
        _burnToken(tokenContract, args, spec, address(0x0));
    }

    /**
     * @dev See {INFT2ERC20-burnToken}.
     */
    function burnToken(address tokenContract, uint256[] calldata args, string calldata spec, address receiver) public override nonReentrant {
        _burnToken(tokenContract, args, spec, receiver);
    }

    function _burnToken(address tokenContract, uint256[] calldata args, string calldata spec, address receiver) private {
        require(args.length > 0, "Must provide at least one argument");
        require(_rateEngine != address(0), "Rate Engine not configured");
        require(_specTransferFunction[spec] != bytes4(0x0), "Transfer function not defined for spec");
        uint256 rate = INFT2ERC20RateEngine(_rateEngine).getRate(totalSupply(), tokenContract, args, spec);

        bytes memory byteArgs = abi.encode(args[0]);
        if (args.length > 1) {
            // Encode value params and burn token
            for (uint i = 1; i < args.length; i++) {
                byteArgs = abi.encodePacked(byteArgs, args[i]);
            }
            (bool success, bytes memory returnData) = tokenContract.call(abi.encodePacked(_specTransferFunction[spec], uint256(uint160(msg.sender)), uint256(0xdEaD), byteArgs));
            require(success, "Burn failure");
        } else {
            // Burn the token
            (bool success, bytes memory returnData) = tokenContract.call(abi.encodeWithSelector(_specTransferFunction[spec], msg.sender, address(0xdEaD), args[0]));
            require(success, "Burn failure");
        }

        if (receiver == address(0x0)) {        
            _mint(msg.sender, rate);
            emit Swapped(msg.sender, tokenContract, args, spec, rate);
        } else {
            _mint(receiver, rate);
            emit Swapped(receiver, tokenContract, args, spec, rate);
        }

        // Treasury gets additional minted ash
        if (_treasuryBasisPoints > 0 && _treasury != address(0x0)) {
            uint256 treasuryRate = (rate*_treasuryBasisPoints)/10000;
            if (treasuryRate > 0) {
                _mint(_treasury, treasuryRate);
            }
        }

    }

    
}