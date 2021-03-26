pragma solidity >=0.5.15  <=0.5.17;

import "./Maker.sol";
import "./Market.sol";
import "./interface/IManager.sol";
import "./interface/IFactory.sol";

contract Factory is IFactory {

    event MarketCreated(address market, address maker, uint256 price, address clearAnchor, uint8 marketType);

    address public manager;

    mapping(uint256 => mapping(address => address)) public getMarket;
    mapping(uint256 => mapping(address => address)) public getMaker;

    mapping(address => address) public getMarketByMaker;
    mapping(address => address) public getMakerByMarket;

    mapping(address => address) public getMarketClearAnchor;
    mapping(address => address) public getMakerClearAnchor;

    constructor(address _manager) public {
        require(_manager != address(0), "Factory:constructor _manager is zero address");
        manager = _manager;
    }

    function createPair(
        uint256 _indexPrice,
        address _clearAnchor,
        uint8 _marketType,
        uint _ratio,
        string calldata _lpTokenName
    ) external onlyController {
        require(getMarket[_indexPrice][_clearAnchor] == address(0), "already created");
        require(_marketType == 0 || _marketType == 1 || _marketType == 2, 'marketType error');
        require(_ratio > 0, "ratio zero");

        Market market = new Market(manager);
        Maker maker = new Maker(manager);

        getMarket[_indexPrice][_clearAnchor] = address(market);
        getMaker[_indexPrice][_clearAnchor] = address(maker);
        getMarketByMaker[address(maker)] = address(market);
        getMakerByMarket[address(market)] = address(maker);
        getMarketClearAnchor[address(market)] = _clearAnchor;
        getMakerClearAnchor[address(maker)] = _clearAnchor;

        market.initialize(_indexPrice, _clearAnchor, _ratio, address(maker), _marketType);
        maker.initialize(_indexPrice, _clearAnchor, address(market), _marketType, _lpTokenName);

        emit MarketCreated(address(market), address(maker), _indexPrice, _clearAnchor, _marketType);
    }

    modifier onlyController{
        require(IManager(manager).checkController(msg.sender), "only Controller");
        _;
    }
}
