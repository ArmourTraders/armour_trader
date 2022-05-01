// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IfactoryV1{
    function giveOutRewards() external;
}
contract Guarantee {
    address _factory;
    address _partA;
    address _partB;
    address _coinAddress;
    address _coinStorage;
    uint256 _amount;
    enum State {CREATE,CANCEL,CONFIRMED,COMPLETED}
    State _state;

    constructor(address partA, address partB, address coinAddress, uint256 amount,address coinStorage) {
        _factory = msg.sender;
        _partA = partA;
        _partB = partB;
        _coinAddress = coinAddress;
        _coinStorage = coinStorage;
        _amount = amount;
        _state = State.CREATE;
    }
    
    modifier onlyFactory(){
        require(msg.sender == _factory, "not factory");
        _;
    }
    modifier onlyPartA(){
        require(msg.sender == _partA, "not partA");
        _;
    }
    modifier onlyPartB(){
        require(msg.sender == _partB, "not partB");
        _;
    }

    modifier atState(State state) {
        require(_state == state, "The current state of contract is not support the operation!");
        _;
    }
    function getState() public view returns(State)
    {
        return _state;
    }
    /**
    * only at cancel state 
    *
    **/
    function partAWithdraw() public onlyPartA atState(State.CANCEL) {
        IERC20 coin = IERC20(_coinAddress);
        coin.transfer(_partA,_amount);
        _state = State.COMPLETED;
    }

    function _giveOutRewards() private{
        IfactoryV1 factory = IfactoryV1(_factory);
        factory.giveOutRewards();
    }

    /**
    * only at success state 
    *
    **/
    function partBWithdraw() public onlyPartB atState(State.CONFIRMED) {
        IERC20 coin = IERC20(_coinAddress);
        coin.transfer(_partB,_amount * 999 / 1000);  
        coin.transfer(_coinStorage,_amount / 1000);      
        _giveOutRewards();
        _state = State.COMPLETED;
    }

   
    /**
    * cancel the contract, and then unlock the  Amount of PartA, only PartB can do this operation
    *
    **/
    function cancel() public onlyPartB atState(State.CREATE){
        _state = State.CANCEL;
    }

   
    /**
    * PartA confirmed the confirm of PartB, only PartA can do this operation
    *
    **/
    function confirmed() public onlyPartA atState(State.CREATE){
        _state = State.CONFIRMED;
    }

    //belong == 0 means property belongs to partA otherwise belong == 1 means property belongs to partB
    function solveConflictByJudge(uint8 belong) public onlyFactory {
        if (belong == 0) _state = State.CANCEL;
        if (belong == 1) _state = State.CONFIRMED;
    } 
}
