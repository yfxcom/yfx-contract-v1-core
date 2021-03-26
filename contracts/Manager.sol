pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IMaker.sol";
import "./interface/IMarket.sol";
import "./interface/IManager.sol";

contract Manager is IManager {

    address public owner;
    address public signer;
    address public controller;
    address public router;
    address public taker;               // contract User address
    address public feeOwner;
    address public riskFundingOwner;
    address public poolFeeOwner;

    uint256 public cancelBlockElapse;
    uint256 public openLongBlockElapse;

    bool public paused = true;

    mapping(uint256 => mapping(address => address)) public getMarket;
    mapping(uint256 => mapping(address => address)) public getMaker;

    mapping(address => address) public getMarketByMaker;
    mapping(address => address) public getMakerByMarket;

    mapping(address => address) public getMarketClearAnchor;
    mapping(address => address) public getMakerClearAnchor;

    event MarketCreated(address market, address maker, uint256 price, address clearAnchor, uint8 marketType);

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
        require(_cancelBlockElapse > 0, "_cancelBlockElapse zero");
        cancelBlockElapse = _cancelBlockElapse;
    }

    function changeOpenLongBlockElapse(uint256 _openLongBlockElapse) external onlyController {
        require(_openLongBlockElapse > 0, "_openLongBlockElapse zero");
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
        return getMarketClearAnchor[_market] != address(0);
    }

    function checkMaker(address _maker) external view returns (bool) {
        return getMakerClearAnchor[_maker] != address(0);
    }

    function createPair(
        address maker,
        address market,
        uint256 _indexPrice,
        address _clearAnchor,
        uint8 _marketType,
        uint _ratio,
        string calldata _lpTokenName
    ) external onlyController {
        require(getMarket[_indexPrice][_clearAnchor] == address(0), "already created");
        require(_marketType == 0 || _marketType == 1 || _marketType == 2, 'marketType error');
        require(maker != address(0) && market != address(0), 'market and maker is not address(0)');
        require(_ratio > 0,'_ratio is zero');
        require(getMarketByMaker[maker] == address(0), 'market already exist');
        require(getMakerByMarket[market] == address(0), 'maker already exist');

        getMarket[_indexPrice][_clearAnchor] = market;
        getMaker[_indexPrice][_clearAnchor] = maker;
        getMarketByMaker[maker] = market;
        getMakerByMarket[market] = maker;
        getMarketClearAnchor[market] = _clearAnchor;
        getMakerClearAnchor[maker] = _clearAnchor;

        IMarket(market).initialize(_indexPrice, _clearAnchor, _ratio, maker, _marketType);
        IMaker(maker).initialize(_indexPrice, _clearAnchor, market, _marketType, _lpTokenName);

        emit MarketCreated(market, maker, _indexPrice, _clearAnchor, _marketType);
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
