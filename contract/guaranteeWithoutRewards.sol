// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Guarantee {
    address _factory;
    address _partyA;
    address _partyB;
    address _coinAddress;
    address _coinStorage;
    uint256 _amount;
    enum State {CREATE,CANCEL,CONFIRMED,COMPLETED}
    State _state;

    constructor(address partyA, address partyB, address coinAddress, uint256 amount,address coinStorage) {
        _factory = msg.sender;
        _partyA = partyA;
        _partyB = partyB;
        _coinAddress = coinAddress;
        _coinStorage = coinStorage;
        _amount = amount;
        _state = State.CREATE;
    }
    
    modifier onlyFactory(){
        require(msg.sender == _factory, "not factory");
        _;
    }
    modifier onlypartyA(){
        require(msg.sender == _partyA, "not partyA");
        _;
    }
    modifier onlypartyB(){
        require(msg.sender == _partyB, "not partyB");
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
    function partyAWithdraw() public onlypartyA atState(State.CANCEL) {
        IERC20 coin = IERC20(_coinAddress);
        coin.transfer(_partyA,_amount);
        _state = State.COMPLETED;
        emit partyAWithdrawed(address(this));
    }

    /**
    * only at success state 
    *
    **/
    function partyBWithdraw() public onlypartyB atState(State.CONFIRMED) {
        IERC20 coin = IERC20(_coinAddress);
        coin.transfer(_partyB,_amount * 999 / 1000);  
        coin.transfer(_coinStorage,_amount / 1000);      
        _state = State.COMPLETED;
        emit partyBWithdrawed(address(this));
    }

   
    /**
    * cancel the contract, and then unlock the  Amount of partyA, only partyB can do this operation
    *
    **/
    function cancel() public onlypartyB atState(State.CREATE){
        _state = State.CANCEL;
        emit partyBCanceled(address(this));
    }

   
    /**
    * partyA confirmed the confirm of partyB, only partyA can do this operation
    *
    **/
    function confirmed() public onlypartyA atState(State.CREATE){
        _state = State.CONFIRMED;
        emit partyAConfirmed(address(this));
    }

    //belong == 0 means property belongs to partyA otherwise belong == 1 means property belongs to partyB
    function solveConflictByJudge(uint8 belong) public onlyFactory {
        if (belong == 0) _state = State.CANCEL;
        if (belong == 1) _state = State.CONFIRMED;
    } 
    event partyAConfirmed(address contractAddress);
    event partyBCanceled(address contractAddress);
    event partyAWithdrawed(address contractAddress);
    event partyBWithdrawed(address contractAddress);
}
