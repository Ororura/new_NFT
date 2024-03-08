// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "contracts/ERC20.sol";

contract Token is ERC20("Professional", "PROFI") {
    address owner;
    address tom;
    address max;
    address jack;

    constructor() {
        owner = msg.sender;
        tom = 0x03E2325A7e8786a168d68A6Ab2a76920570eeBC8;
        max = 0x4290fF646Fa317c56548FC134295FA90dFBEd7bF;
        jack = 0xB16aAaEb0675338efeE80421fF0c8e9C984623Ce;

        _mint(owner, 100_000 * 10**decimals());
        _mint(tom, 200_000 * 10**decimals());
        _mint(max, 300_000 * 10**decimals());
        _mint(jack, 400_000 * 10**decimals());
    }

    function getReward(address _to) public {
        _mint(_to, 100 * 10**decimals());
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function sendTokens(
        address _from,
        address _to,
        uint256 _amount
    ) public {
        _transfer(_from, _to, _amount);
    }
}
