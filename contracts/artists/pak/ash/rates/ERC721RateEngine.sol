// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @author: manifold.xyz


import "openzeppelin-solidity/contracts/utils/introspection/IERC165.sol";

import "../../../../access/AdminControl.sol";
import "../../../../libraries/RealMath.sol";
import "./IERC721RateEngine.sol";

contract ERC721RateEngine is AdminControl, IERC721RateEngine {

    // erc721 contract rate classes
    mapping(address => uint8) private _erc721ContractRateClass;

    // erc721 contract token rate classes (takes precedent)
    mapping(address => mapping(uint256 => uint8)) private _erc721ContractTokenRateClass;

    bool private _enabled = false;

    /**
     * @dev See {IERC721RateEngine-updateEnabled}.
     */
    function updateEnabled(bool enabled) external override adminRequired {
        if (_enabled != enabled) {
            _enabled = enabled;
            emit Enabled(msg.sender, enabled);
        }
    }

    /**
     * @dev See {IERC721RateEngine-updateRate}.
     */
    function updateRateClass(address[] calldata contracts, uint8[] calldata rateClasses) external override adminRequired {
        require(contracts.length == rateClasses.length, "ERC721RateEngine: Mismatched input lengths");
        for (uint i=0; i<contracts.length; i++) {
            require(rateClasses[i] < 3, "ERC721RateEngine: Invalid rate class provided");
            if (_erc721ContractRateClass[contracts[i]] != rateClasses[i]) {
                _erc721ContractRateClass[contracts[i]] = rateClasses[i];
                emit ContractRateClassUpdate(msg.sender, contracts[i], rateClasses[i]);
            }
        }
    }

    /**
     * @dev See {IERC721RateEngine-updateRate}.
     */
    function updateRateClass(address[] calldata contracts, uint256[] calldata tokenIds, uint8[] calldata rateClasses) external override adminRequired {
        require(contracts.length == tokenIds.length && contracts.length == rateClasses.length, "ERC721RateEngine: Mismatched input lengths");
        for (uint i=0; i<contracts.length; i++) {
            require(rateClasses[i] < 3, "ERC721RateEngine: Invalid rate class provided");
            if (_erc721ContractTokenRateClass[contracts[i]][tokenIds[i]] != rateClasses[i]) {
                _erc721ContractTokenRateClass[contracts[i]][tokenIds[i]] = rateClasses[i];
                emit ContractTokenRateClassUpdate(msg.sender, contracts[i], tokenIds[i], rateClasses[i]);
            }
        }
    }

    /**
     * @dev See {INFT2ERC20RateEngine-getRate}.
     */
    function getRate(uint256 totalSupply, address tokenContract, uint256[] calldata args, string calldata spec) external view override returns (uint256) {
        require(_enabled, "ERC721RateEngine: Disabled");
        require(args.length == 1, "ERC721RateEngine: Invalid arguments");
        require(keccak256(bytes(spec)) == keccak256(bytes('erc721')), "ERC721RateEngine: Only ERC721 currently supported");
        uint8 rateClass;
        if (_erc721ContractTokenRateClass[tokenContract][args[0]] != 0) {
           rateClass = _erc721ContractTokenRateClass[tokenContract][args[0]];
        } else {
           rateClass = _erc721ContractRateClass[tokenContract];
        }
        require(rateClass != 0, "ERC721RateEngine: Rate class for token not configured");

        uint256 m = RealMath.rpowApprox(500000000000000000, totalSupply/1000000, 100000000);
        if (rateClass == 1) {
            return m*1000;
        } else if (rateClass == 2) {
            return RealMath.rmul(m, m)<<1;
        }
        revert("Rate class for token not configured.");
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, AdminControl) returns (bool) {
        return interfaceId == type(IERC721RateEngine).interfaceId
            || super.supportsInterface(interfaceId);
    }

    

}