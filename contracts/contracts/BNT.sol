// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BNT is ERC20, Ownable {
    constructor(address treasury, uint256 totalSupply_) ERC20("Blocnet Token", "BNT") Ownable(msg.sender) {
        require(treasury != address(0), "treasury is required");
        require(totalSupply_ > 0, "supply must be > 0");
        _mint(treasury, totalSupply_);
    }
}
