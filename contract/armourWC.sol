// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface ICondition{
    function getCurSatisfiedAmount(uint tokenId,uint totalAmount) external view returns(uint);
}
//this is withdrawal certificate NFT for user to get rewards of take part in ArmourTraders' activity
contract ArmourWC is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public armourTokenAddress;
    address public coinStorageAddress;

    struct WithdrawInfo{
        uint totalAmount;
        uint withdrawnAmount;
        address conditionAddress;
    }

    mapping (uint => WithdrawInfo) infos;

    constructor() ERC721("ArmourWC", "AMRWC") {}

    modifier isOwner(uint tokenId){
        require(ownerOf(tokenId) == msg.sender,"not owner");
        _;
    }

    function setArmourTokenAddress(address _armourTokenAddress) public onlyOwner{
        armourTokenAddress = _armourTokenAddress;
    }

    function setCoinStorageAddress(address _coinStorageAddress) public onlyOwner{
        coinStorageAddress = _coinStorageAddress;
    }

    function _getCurSatisfiedAmount(uint tokenId) internal view returns(uint amount){
        ICondition condition = ICondition(infos[tokenId].conditionAddress);
        amount = condition.getCurSatisfiedAmount(tokenId,infos[tokenId].totalAmount);
    }

    function getTotalAmount(uint tokenId) public view returns(uint amount){
        amount = infos[tokenId].totalAmount;
    }

    function getWithdrawnAmount(uint tokenId) public view returns(uint amount){
        amount = infos[tokenId].withdrawnAmount;
    }

    function getConditionAddress(uint tokenId) public view returns(address conditionAddress){
        conditionAddress = infos[tokenId].conditionAddress;
    }

    
    function getCurSatisfiedAmount(uint tokenId) public view returns(uint amount){
        uint satisfiedAmount = _getCurSatisfiedAmount(tokenId);
        amount = satisfiedAmount - infos[tokenId].withdrawnAmount;
    }

    function withdrawAMR(uint tokenId) public isOwner(tokenId) {
        uint satisfieAmount = getCurSatisfiedAmount(tokenId);
        require(satisfieAmount > 0,"not enough amount");
        infos[tokenId].withdrawnAmount += satisfieAmount;
        IERC20 AMR = IERC20(armourTokenAddress);
        AMR.transfer(msg.sender,satisfieAmount);
    }




    function safeMint(address to,uint totalAmount,address conditionAddress) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        infos[tokenId].totalAmount = totalAmount;
        infos[tokenId].conditionAddress = conditionAddress;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
