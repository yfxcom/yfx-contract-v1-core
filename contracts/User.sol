pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IUser.sol";
import "./interface/IERC20.sol";
import "./interface/IWrappedCoin.sol";
import "./interface/IManager.sol";

import "./library/SafeMath.sol";
import "./library/Address.sol";
import "./library/TransferHelper.sol";
import "./library/ReentrancyGuard.sol";

contract User is IUser, ReentrancyGuard {
    using SafeMath for uint256;

    address public wCoin;                                           // wrapped contract
    address public manager;                                         // manager contract
    mapping(address => bool) public tokenList;                      // tokens supported
    mapping(address => uint256) public totalSupply;                 // token:totalSupply
    mapping(address => mapping(address => uint256)) public balance; // token:owner:balance
    bool public depositPaused = true;
    bool public withdrawPaused = true;

    event Transfer(address token, address from, address to, uint256 value);
    event ReceiveToken(address token, address from, address to, uint256 value);
    event Deposit(address token, address user, uint256 value);
    event Withdraw(address token, address user, uint256 value);
    event AddToken(address token);

    constructor(address _m, address _wCoin) public {
        require(_m != address(0), "invalid manager");
        require(_wCoin != address(0), "invalid wrapped contract");
        manager = _m;
        wCoin = _wCoin;
    }

    function() external payable {
        require(msg.sender == wCoin, "invalid recharge method, please use deposit function");
    }

    modifier onlyController(){
        require(IManager(manager).checkController(msg.sender), "not controller");
        _;
    }

    modifier whenDepositNotPaused() {
        require(!depositPaused, "paused");
        _;
    }

    modifier whenWithdrawNotPaused() {
        require(!withdrawPaused, "paused");
        _;
    }

    modifier onlyMakerOrMarket() {
        require(IManager(manager).checkMarket(msg.sender) || IManager(manager).checkMaker(msg.sender), "insufficient permissions!");
        _;
    }

    function setPaused(bool _depositPaused, bool _withdrawPaused) external onlyController {
       depositPaused = _depositPaused;
       withdrawPaused = _withdrawPaused;
    }

    function addToken(address _token) external onlyController returns (bool){
        require(msg.sender != address(0), "invalid sender address");
        require(_token != address(0), "invalid token address");
        tokenList[_token] = true;

        emit AddToken(_token);
        return true;
    }

/*
    address(0) for tron: 0x410000000000000000000000000000000000000000 or T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb

    deposit coin or token
    coinType: 0 for coin like eth or trx, 1 for token

    example:
    deposit trx:    deposit(0, T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb, 0).send({callValue: 99999})
    deposit token:  deposit(1, token, 99999).send();
*/
    function deposit(uint8 coinType, address token, uint256 value) external nonReentrant whenDepositNotPaused payable {
         require(coinType == 0 || coinType == 1, "invalid coin type!");

        if (coinType == 0) {
             require(token == address(0), "token address must be address(0)!");
             require(tokenList[wCoin], "not in token list");
             require(value == 0, "token value must be 0!");
             require(msg.value > 0, "invalid value!");

            // trx -> WTrx
            IWrappedCoin(wCoin).deposit.value(msg.value)();
            totalSupply[wCoin] = totalSupply[wCoin].add(msg.value);
            balance[wCoin][msg.sender] = balance[wCoin][msg.sender].add(msg.value);

            emit Deposit(wCoin, msg.sender, msg.value);
        }else{
            require(token != address(0), "token address can not be address 0!");
            require(Address.isContract(token), "token must be a contract address!");
            require(tokenList[token], "not in token list");
            require(value > 0, "invalid value!");

            TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
            totalSupply[token] = totalSupply[token].add(value);
            balance[token][msg.sender]=balance[token][msg.sender].add(value);

            emit Deposit(token, msg.sender, value);
         }
    }

/*
    withdraw coin or token
    coinType: 0 fro coin like eth or trx, 1 for token

    example:
    withdraw trx:   withdraw(0, T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb, 99999).send();
    withdraw token: withdraw(1, token, 99999).send();
*/
    function withdraw(uint8 coinType, address token, uint256 value) external nonReentrant whenWithdrawNotPaused {
        require(coinType == 0 || coinType == 1, "invalid coin type!");
        require(value > 0, "invalid value!");

        if (coinType == 0) {
            require(token == address(0), "token address must be address 0!");
            require(balance[wCoin][msg.sender] >= value);

            totalSupply[wCoin] = totalSupply[wCoin].sub(value);
            balance[wCoin][msg.sender] = balance[wCoin][msg.sender].sub(value);
            IWrappedCoin(wCoin).withdraw(value);
            TransferHelper.safeTransferETH(msg.sender, value);

            emit Withdraw(wCoin, msg.sender, value);
         }else{
            require(token != address(0), "token address can not be address 0!");
            require(Address.isContract(token), "token must be a contract address!");
            require(balance[token][msg.sender] >= value, "insufficient balance");

            totalSupply[token] = totalSupply[token].sub(value);
            balance[token][msg.sender] = balance[token][msg.sender].sub(value);
            TransferHelper.safeTransfer(token, msg.sender, value);

            emit Withdraw(token, msg.sender, value);
        }
    }

    function transfer(address token, address fromUser, uint256 value) external nonReentrant onlyMakerOrMarket returns (bool){
        require(token != address(0), "token address can not be address 0");
        require(fromUser != address(0), "fromUser address can not be address 0");
        require(value > 0, "invalid value");
        require(balance[token][fromUser] >= value, "insufficient balance");

        totalSupply[token] = totalSupply[token].sub(value);
        balance[token][fromUser] = balance[token][fromUser].sub(value);
        TransferHelper.safeTransfer(token, msg.sender, value);

        emit Transfer(token, fromUser, msg.sender, value);
        return true;
    }

    function receiveToken(address token, address toUser, uint256 value) external nonReentrant onlyMakerOrMarket returns (bool){
        require(token != address(0), "token address can not be address 0");
        require(toUser != address(0), "toUser address can not be address 0");
        require(value > 0, "invalid value");
        totalSupply[token] = totalSupply[token].add(value);
        balance[token][toUser] = balance[token][toUser].add(value);

        emit ReceiveToken(token, msg.sender, toUser, value);
        return true;
    }
}
