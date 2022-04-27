// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ArmourToken is ERC20, ERC20Burnable, ERC20Snapshot,Ownable {
    mapping(address => bool) factoryMintableStates;
    uint256 private _cap;

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    constructor(address coinStorage) ERC20("ArmourToken", "AMR"){
        //totalSupply = 0.1 billion
        _cap = (10**8) * (10**decimals());
        _mint(coinStorage, 2*(10**7)*(10**decimals()));
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function enableFactoryMint(address factoryAddress) public onlyOwner{
        factoryMintableStates[factoryAddress] = true;
    }

    function disableFactoryMint(address factoryAddress) public onlyOwner{
        factoryMintableStates[factoryAddress] = false;
    }


    modifier factoryMintable{
        require(factoryMintableStates[msg.sender],"this factory cannot Mint");
        _;
    }

    function mint(address to, uint256 amount) public factoryMintable {
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override (ERC20){
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(to, amount);
    }
}
