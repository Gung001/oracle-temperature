// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev TODO the reward of oracle of the temperature.
 */
contract TemperatureToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("TemperatureToken", "TT") {
        _mint(msg.sender, initialSupply);
    }
}