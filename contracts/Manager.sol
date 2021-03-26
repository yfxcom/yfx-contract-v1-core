pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IManager.sol";
import "./interface/IFactory.sol";

contract Manager is IManager {

    address public owner;
    address public signer;
    address public factory;
    address public controller;
    address public router;
    address public taker;               // contract User address
    address public feeOwner;
    address public riskFundingOwner;
    address public poolFeeOwner;

    uint256 public cancelBlockElapse;
    uint256 public openLongBlockElapse;

    bool public paused = true;

    function pause() external  onlyController {
        require(!paused, "already paused");
        paused = true;
    }

    function unpause() external  onlyController {
        require(paused, "not paused");
        paused = false;
    }

    constructor(address _owner) public {
        require(_owner != address(0), "Manager:constructor _owner is zero address");
        owner = _owner;
        controller = msg.sender;
    }

    function changeOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "address zero");
        owner = _owner;
    }

    function notifyRouter(address _router) external onlyController {
        require(router == address(0), "router already notify");
        require(_router != address(0), "address zero");
        router = _router;
    }

    function notifyTaker(address _taker) external onlyController {
        require(taker == address(0), "taker already notify");
        require(_taker != address(0), "address zero");
        taker = _taker;
    }

    function notifySigner(address _signer) external onlyController {
        require(_signer != address(0), "address zero");
        signer = _signer;
    }

    function notifyFactory(address _factory) external onlyController {
        require(factory == address(0), "factory already notify");
        require(_factory != address(0), "address zero");
        factory = _factory;
    }

    function notifyController(address _controller) external {
        require(_controller != address(0), "address zero");
        require(msg.sender == owner || msg.sender == controller, "only controller");
        controller = _controller;
    }

    function notifyFeeOwner(address _feeOwner) external onlyController {
        require(_feeOwner != address(0), "address zero");
        feeOwner = _feeOwner;
    }

    function notifyRiskFundingOwner(address _riskFundingOwner) external onlyController {
        require(_riskFundingOwner != address(0), "address zero");
        riskFundingOwner = _riskFundingOwner;
    }

    function notifyPoolFeeOwner(address _poolFeeOwner) external onlyController {
        require(_poolFeeOwner != address(0), "address zero");
        poolFeeOwner = _poolFeeOwner;
    }

    function changeCancelBlockElapse(uint256 _cancelBlockElapse) external onlyController {
        require(_cancelBlockElapse > 0, "_cancelBlockElapse is zero");
        cancelBlockElapse = _cancelBlockElapse;
    }

    function changeOpenLongBlockElapse(uint256 _openLongBlockElapse) external onlyController {
        require(_openLongBlockElapse > 0, "_openLongBlockElapse is zero");
        openLongBlockElapse = _openLongBlockElapse;
    }


    function checkSigner(address _signer) external view returns (bool) {
        return _signer == signer;
    }

    function checkController(address _controller) view external returns (bool) {
        return _controller == controller;
    }

    function checkRouter(address _router) external view returns (bool) {
        return _router == router;
    }

    function checkMarket(address _market) external view returns (bool) {
        return IFactory(factory).getMarketClearAnchor(_market) != address(0);
    }

    function checkMaker(address _maker) external view returns (bool) {
        return IFactory(factory).getMakerClearAnchor(_maker) != address(0);
    }


    modifier onlyController{
        require(msg.sender == controller, "only controller");
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "only owner");
        _;
    }
}
