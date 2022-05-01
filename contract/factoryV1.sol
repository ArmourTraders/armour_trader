// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "./guarantee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./armourToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract FactoryV1 is Ownable{
    struct GuaranteInfo{
        address partA;
        address partB;
        address coinAddress;
        uint256 amount;
        bool judgeSolve;
        bool notReward;
    }
    struct SupportCoinInfo{
        bool supported;
        uint8 rewardRatio;
    }
    address private _armourTokenAddress;
    address private _owner;
    address private _judge;
    address private _coinStorage;
    
    mapping(address => SupportCoinInfo) private _supportCoins;
    mapping(address => GuaranteInfo) private _guaranteeContracts;
    constructor(){
        _owner = msg.sender;
    }

    function getAppealStatus(address guarantee) public view returns(bool){
        return _guaranteeContracts[guarantee].judgeSolve;
    }

    function setArmourTokenAddress(address ArmourTokenAddress) public onlyOwner{
        _armourTokenAddress = ArmourTokenAddress;
    }

    function setCoinStorage(address coinStorage) public onlyOwner{
        _coinStorage = coinStorage;
    }

    modifier onlyJudge {
        require(msg.sender == _judge,"not judge");
        _;
    }


    function assignJudge(address judgeAddress) public onlyOwner {
        _judge = judgeAddress;
    }

    function enableSupportCoin(address coinAddress,uint8 rewardRatio) public onlyOwner {
        _supportCoins[coinAddress].supported = true;
        _supportCoins[coinAddress].rewardRatio = rewardRatio;
    }

    function disableSupportCoin(address coinAddress) public onlyOwner {
        _supportCoins[coinAddress].supported = false;
    }

    function setSupportCoinReward(address coinAddress,uint8 rewardRatio) public onlyOwner {
        _supportCoins[coinAddress].rewardRatio = rewardRatio;
    }

    function createGuaranteeContractAndLockAssets(address partB,address coinAddress,uint256 amount) public returns(address guaranteeAddress){
        require(_supportCoins[coinAddress].supported,"this coin not supported!");
        IERC20 coin = IERC20(coinAddress);
        require(coin.allowance(msg.sender,address(this)) > amount,"please appove");
        Guarantee guaranteeContract = new Guarantee(msg.sender,partB,coinAddress,amount,_coinStorage); 
        guaranteeAddress = address(guaranteeContract); 
        emit createGuaranteeContract(guaranteeAddress,msg.sender,partB,coinAddress,amount);

        _guaranteeContracts[guaranteeAddress].partA = msg.sender;
        _guaranteeContracts[guaranteeAddress].partB = partB;
        _guaranteeContracts[guaranteeAddress].coinAddress = coinAddress;
        _guaranteeContracts[guaranteeAddress].amount = amount;
        _guaranteeContracts[guaranteeAddress].notReward = true;
        coin.transferFrom(msg.sender,guaranteeAddress,amount);
    }

    function applySolveConflictByJudge(address guaranteeContractAddress) public{
        require(_guaranteeContracts[guaranteeContractAddress].partA == msg.sender || 
        _guaranteeContracts[guaranteeContractAddress].partB == msg.sender);
        _guaranteeContracts[guaranteeContractAddress].judgeSolve = true;
    }
    
    //belong == 0 means property belongs to partA otherwise belong == 1 means property belongs to partB
    function solveConflictByJudge(address guaranteeContractAddress,uint8 belong) public onlyJudge returns(bool){
        require(_guaranteeContracts[guaranteeContractAddress].judgeSolve,"judge can't solve this conflict");
        require(belong == 0 || belong == 1,"input is wrong");
        Guarantee guarantee = Guarantee(guaranteeContractAddress);
        guarantee.solveConflictByJudge(belong);
        return true;
    }

    function giveOutRewards() public{
        require(_guaranteeContracts[msg.sender].notReward,"only guaranteeContract can call this function");
        ArmourToken armourToken = ArmourToken(_armourTokenAddress);
        //10% reward to partA 
        uint256 partAReward = _guaranteeContracts[msg.sender].amount/1000 /10 * _supportCoins[_guaranteeContracts[msg.sender].coinAddress].rewardRatio;
        //110% reward to partB 
        uint256 partBReward = _guaranteeContracts[msg.sender].amount/1000 /10 * 11 * _supportCoins[_guaranteeContracts[msg.sender].coinAddress].rewardRatio;
        armourToken.mint(_guaranteeContracts[msg.sender].partA,partAReward);
        armourToken.mint(_guaranteeContracts[msg.sender].partB,partBReward);
        _guaranteeContracts[msg.sender].notReward = false;
    }
    event createGuaranteeContract(address guaranteeAddress,address partA,address partB,address coinAddresss,uint amount);

}