pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IUser.sol";
import "./interface/IERC20.sol";
import "./interface/IWrappedCoin.sol";
import "./interface/IManager.sol";

import "./library/SafeMath.sol";
import "./library/Address.sol";
import "./library/TransferHelper.sol";
import "./library/ReentrancyGuard.sol";
import './library/SignatureDecode.sol';

contract User is IUser, ReentrancyGuard {
    using SafeMath for uint256;

    address public wCoin;                                           // wrapped contract
    address public manager;                                         // manager contract
    address public bridge;
    mapping(address => bool) public tokenList;                      // tokens supported
    mapping(address => uint256) public totalSupply;                 // token:totalSupply
    mapping(address => mapping(address => uint256)) public balance; // token:owner:balance
    bool public depositPaused = true;
    bool public withdrawPaused = true;

    string public constant name = "YFX";
    string public constant version = "1";
    // EIP712 niceties
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_DEPOSIT_TYPEHASH = 'DepositPermit(address sender,uint256 nonce,address token,uint256 value)'
    bytes32 public constant PERMIT_DEPOSIT_TYPEHASH = 0x85a59a64ff9ae702c630b8b133cc7eb77ff7e1290e9cd3c596d29a0913ce7f66;

    // bytes32 public constant PERMIT_WITHDRAW_TYPEHASH = 'WithdrawPermit(address sender,uint256 nonce,address token,uint256 value)'
    bytes32 public constant PERMIT_WITHDRAW_TYPEHASH = 0x780d9cfdc1d61d9a5ca0907790f3045b9aafb185846f83a11884aa8024098a2f;

    // bytes32 public constant PERMIT_WITHDRAWBYAMBBRIDGE_TYPEHASH = 'WithdrawByAMBBridgePermit(address sender,uint256 nonce,address token,uint256 value)'
    bytes32 public constant PERMIT_WITHDRAWBYAMBBRIDGE_TYPEHASH = 0xbcff8962f6ca764290c2af39f3dab124bb708d97890dd0ae0b5413f4d511767f;

    mapping(address => uint256) public nonces;

    event Transfer(address token, address from, address to, uint256 value);
    event ReceiveToken(address token, address from, address to, uint256 value);
    event Deposit(address token, address user, uint256 value);
    event Withdraw(address token, address user, uint256 value);
    event AddToken(address token);

    constructor(address _m, address _wCoin, uint256 chainId) public {
        require(_m != address(0), "invalid manager");
        require(_wCoin != address(0), "invalid wrapped contract");
        manager = _m;
        wCoin = _wCoin;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                chainId,
                address(this)
            )
        );
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

    function setBridge(address _bridge) external onlyController {
        require(_bridge != address(0), "invalid bridge");
        bridge = _bridge;
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
        } else {
            require(token != address(0), "token address can not be address 0!");
            require(Address.isContract(token), "token must be a contract address!");
            require(tokenList[token], "not in token list");
            require(value > 0, "invalid value!");

            TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
            totalSupply[token] = totalSupply[token].add(value);
            balance[token][msg.sender] = balance[token][msg.sender].add(value);

            emit Deposit(token, msg.sender, value);
        }
    }

    function depositPermit(address _sender, uint256 _nonce, address token, uint256 value, bytes calldata _sign) external nonReentrant whenDepositNotPaused payable {
        require(_sender != address(0));

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_DEPOSIT_TYPEHASH, _sender, _nonce, token, value))
            )
        );

        (bytes32 _r, bytes32 _s,uint8 _v) = SignatureDecode.decode(_sign);

        require(_sender == ecrecover(digest, _v, _r, _s));
        require(_nonce == nonces[_sender]++);

        require(token != address(0), "token address can not be address 0!");
        require(Address.isContract(token), "token must be a contract address!");
        require(tokenList[token], "not in token list");
        require(value > 0, "invalid value!");

        TransferHelper.safeTransferFrom(token, _sender, address(this), value);
        totalSupply[token] = totalSupply[token].add(value);
        balance[token][_sender] = balance[token][_sender].add(value);

        emit Deposit(token, _sender, value);
    }

    /*
        withdraw coin or token
        coinType: 0 fro coin like eth or trx, 1 for token

        example:
        withdraw trx:   withdraw(0, T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb, 99999).send();
        withdraw token: withdraw(1, token, 99999).send();
    */

    function withdraw(uint8 coinType, address token, uint256 value) external nonReentrant whenWithdrawNotPaused {
        _withdraw(msg.sender, coinType, token, value);
    }

    function withdrawPermit(address _sender, uint256 _nonce, address token, uint256 value, bytes calldata _sign) external nonReentrant whenWithdrawNotPaused {
        require(_sender != address(0), 'invalid _sender');

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_WITHDRAW_TYPEHASH, _sender, _nonce, token, value))
            )
        );

        (bytes32 _r, bytes32 _s,uint8 _v) = SignatureDecode.decode(_sign);

        require(_sender == ecrecover(digest, _v, _r, _s), 'invalid sign');
        require(_nonce == nonces[_sender]++, 'invalid nonce');

        _withdraw(_sender, 1, token, value);
    }

    function withdrawByAMBBridgePermit(address _sender, uint256 _nonce, address token, uint256 value, bytes calldata _sign) external nonReentrant whenWithdrawNotPaused {
        require(_sender != address(0), 'invalid _sender');

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_WITHDRAWBYAMBBRIDGE_TYPEHASH, _sender, _nonce, token, value))
            )
        );

        (bytes32 _r, bytes32 _s,uint8 _v) = SignatureDecode.decode(_sign);

        require(_sender == ecrecover(digest, _v, _r, _s), 'invalid sign');
        require(_nonce == nonces[_sender]++, 'invalid nonce');

        require(token != address(0), "token address can not be address 0!");
        require(Address.isContract(token), "token must be a contract address!");
        require(balance[token][_sender] >= value, "insufficient balance");

        totalSupply[token] = totalSupply[token].sub(value);
        balance[token][_sender] = balance[token][_sender].sub(value);

        IERC20(token).approve(bridge, value);

        (bool success, bytes memory data) = address(bridge).call(abi.encodeWithSelector(0xad58bdd1, token, _sender, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'withdraw:withdrawByAMBBridgePermit fail');

        IERC20(token).approve(bridge, 0);

        emit Withdraw(token, _sender, value);
    }

    function _withdraw(address owner, uint8 coinType, address token, uint256 value) internal {
        require(coinType == 0 || coinType == 1, "invalid coin type!");
        require(value > 0, "invalid value!");

        if (coinType == 0) {
            require(token == address(0), "token address must be address 0!");
            require(balance[wCoin][owner] >= value);

            totalSupply[wCoin] = totalSupply[wCoin].sub(value);
            balance[wCoin][owner] = balance[wCoin][owner].sub(value);
            IWrappedCoin(wCoin).withdraw(value);
            TransferHelper.safeTransferETH(owner, value);

            emit Withdraw(wCoin, owner, value);
        } else {
            require(token != address(0), "token address can not be address 0!");
            require(Address.isContract(token), "token must be a contract address!");
            require(balance[token][owner] >= value, "insufficient balance");

            totalSupply[token] = totalSupply[token].sub(value);
            balance[token][owner] = balance[token][owner].sub(value);
            TransferHelper.safeTransfer(token, owner, value);

            emit Withdraw(token, owner, value);
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
