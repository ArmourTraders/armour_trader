// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
import "./guarantee.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract FactoryV1 is Ownable{
    struct GuaranteInfo{
        address partyA;
        address partyB;
        address coinAddress;
        uint256 amount;
        bool judgeSolve;
    }

    address private _owner;
    address private _judge;
    address private _coinStorage;
    
    mapping(address => bool) private _supportCoins;
    mapping(address => GuaranteInfo) private _guaranteeContracts;
    constructor(){
        _owner = msg.sender;
    }

    function getAppealStatus(address guarantee) public view returns(bool){
        return _guaranteeContracts[guarantee].judgeSolve;
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

    function enableSupportCoin(address coinAddress) public onlyOwner {
        _supportCoins[coinAddress] = true;
    }

    function disableSupportCoin(address coinAddress) public onlyOwner {
        _supportCoins[coinAddress] = false;
    }

    function createGuaranteeContractAndLockAssets(address partyB,address coinAddress,uint256 amount) public returns(address guaranteeAddress){
        require(_supportCoins[coinAddress],"this coin not supported!");
        IERC20 coin = IERC20(coinAddress);
        require(coin.allowance(msg.sender,address(this)) > amount,"please appove");

        Guarantee guaranteeContract = new Guarantee(msg.sender,partyB,coinAddress,amount,_coinStorage); 
        guaranteeAddress = address(guaranteeContract); 
        emit createGuaranteeContract(guaranteeAddress,msg.sender,partyB,coinAddress,amount);

        _guaranteeContracts[guaranteeAddress].partyA = msg.sender;
        _guaranteeContracts[guaranteeAddress].partyB = partyB;
        _guaranteeContracts[guaranteeAddress].coinAddress = coinAddress;
        _guaranteeContracts[guaranteeAddress].amount = amount;

        coin.transferFrom(msg.sender,guaranteeAddress,amount);
    }

    function appealResolveDisputeByJudge(address guaranteeContractAddress) public{
        require(_guaranteeContracts[guaranteeContractAddress].partyA == msg.sender || 
        _guaranteeContracts[guaranteeContractAddress].partyB == msg.sender);
        _guaranteeContracts[guaranteeContractAddress].judgeSolve = true;
        emit appealResolveDispute(guaranteeContractAddress,msg.sender,0);
    }
    
    //belong == 0 means property belongs to partyA otherwise belong == 1 means property belongs to partyB
    function ResolveDisputeByJudge(address guaranteeContractAddress,uint8 belong) public onlyJudge returns(bool){
        require(_guaranteeContracts[guaranteeContractAddress].judgeSolve,"judge can't solve this conflict");
        require(belong == 0 || belong == 1,"input is wrong");
        Guarantee guarantee = Guarantee(guaranteeContractAddress);
        guarantee.solveConflictByJudge(belong);
        emit ResolveDispute(guaranteeContractAddress,belong,0);
        return true;
    }

    event createGuaranteeContract(address guaranteeAddress,address partyA,address partyB,address coinAddresss,uint amount);
    //method = 0 means appeal Resolve Dispute by judge
    //method = 1 means appeal Resolve Dispute by DAO member(to be develop)
    event appealResolveDispute(address guaranteeAddress,address who,uint8 method);

    /**
    *belong == 0 means property belongs to partyA
    *belong == 1 means property belongs to partyB
    *method = 0 means appeal Dispute by judge
    *method = 1 means appeal Dispute by DAO member(to be develop)
    */
    event ResolveDispute(address guaranteeAddress,uint8 belong,uint8 method);


}