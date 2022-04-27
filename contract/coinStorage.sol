// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./armourToken.sol";
contract CoinStorage is Ownable{
    address _armourTokenAddress;
    
    mapping(uint256 => uint256) _snapshotToDividendAmount;
    uint _snapshotCnt = 0 ;
    mapping(address =>mapping(uint256 => bool)) _userShareInfo;
    
    function setArmourTokenAddress(address armourToken) public onlyOwner{
        _armourTokenAddress = armourToken;
    }
    function withdraw(address coinAddress,address to,uint256 amount) public onlyOwner{
        IERC20 coin = IERC20(coinAddress);
        coin.transfer(to,amount);
    }

    function getCurSnapShotCnt() public view returns(uint){
        return _snapshotCnt;
    }

    function depositDividend(uint256 amount,uint256 snapshotId) public{
        ArmourToken coin = ArmourToken(_armourTokenAddress);
        require(snapshotId > _snapshotCnt,"this snapshotId already deposit" );
        require(coin.allowance(msg.sender,address(this))>amount,"please approve to transfer");
        require(coin.balanceOf(msg.sender)>amount,"Not enough armourTokens");
        coin.transferFrom(msg.sender,address(this),amount);
        _snapshotToDividendAmount[snapshotId] += amount;
        _snapshotCnt += 1;
    }

    function checkShareOfDividend(address user,uint256 snapshotId) public view returns(uint256){
        ArmourToken coin = ArmourToken(_armourTokenAddress);
        uint totalSupply = coin.totalSupplyAt(snapshotId) - coin.balanceOfAt(address(this),snapshotId);
        uint userAmount = coin.balanceOfAt(user,snapshotId);
        uint userShare = userAmount * _snapshotToDividendAmount[snapshotId]/totalSupply;
        return userShare;
    }

    function checkWithdrawState(address user,uint256 snapshotId) public view returns(bool){
        return _userShareInfo[user][snapshotId];
    }

    function withdrawShareOfDividend(uint256 snapshotId) public returns(uint256){        
        ArmourToken coin = ArmourToken(_armourTokenAddress);
        require(coin.balanceOfAt(msg.sender,snapshotId) > 0,"No share");
        require(!this.checkWithdrawState(msg.sender,snapshotId),"already withdraw");
        uint userShare = this.checkShareOfDividend(msg.sender,snapshotId);
        coin.transfer(msg.sender,userShare);
        _userShareInfo[msg.sender][snapshotId] = true;
        return userShare;
    }

}