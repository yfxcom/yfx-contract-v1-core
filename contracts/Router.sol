pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IMarket.sol";
import "./interface/IMaker.sol";
import './interface/IManager.sol';

contract Router {
    address manager;

    event TakerOpen(address market, uint256 id);
    event Open(address market, uint256 id);
    event TakerClose(address market, uint256 id);
    event DepositMargin(address market, uint256 id);
    event Close(address market, uint256 id);
    event Cancel(address market, uint256 id);
    event AddLiquidity(uint id, address makeraddress, uint amount, uint256 deadline);
    event RemoveLiquidity(uint id, address makeraddress, uint liquidity, uint256 deadline);
    event CancelAddLiquidity(uint id, address makeraddress);
    event PriceToAddLiquidity(uint id, address makeraddress);
    event PriceToRemoveLiquidity(uint id, address makeraddress);
    event CancelRemoveLiquidity(uint id, address makeraddress);

    constructor(address _manager) public {
        require(_manager != address(0), "Router:constructor _manager is zero address");
        manager = _manager;
    }

    modifier onlyPriceProvider() {
        require(IManager(manager).checkSigner(msg.sender), "caller is not the priceprovider");
        require(address(0) != msg.sender, "caller is not the priceprovider");
        _;
    }

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'Router: EXPIRED');
        _;
    }

    modifier onlyMakerOrMarket(address _marketOrMaker){
        (bool isMarket) = IManager(manager).checkMarket(_marketOrMaker);
        (bool isMaker) = IManager(manager).checkMaker(_marketOrMaker);
        require(isMarket || isMaker, "Insufficient permissions!");
        _;
    }

    function takerOpen(
        address _market,
        address inviter,
        uint128 minPrice,
        uint128 maxPrice,
        uint256 margin,
        uint16 leverage,
        int8 direction,
        uint256 deadline
    ) external ensure(deadline) onlyMakerOrMarket(_market) {
        uint256 id = IMarket(_market).open(msg.sender, inviter, minPrice, maxPrice, margin, leverage, direction);
        emit TakerOpen(_market, id);
    }

    function takerClose(address _market, uint256 id, uint128 minPrice, uint128 maxPrice, uint256 deadline) external ensure(deadline) onlyMakerOrMarket(_market) {
        IMarket(_market).close(msg.sender, id, minPrice, maxPrice);
        emit TakerClose(_market, id);
    }

    function takerOpenCancel(address _market, uint256 id) external onlyMakerOrMarket(_market) {
        IMarket(_market).openCancel(msg.sender, id);
        emit Cancel(_market, id);
    }

    function takerCloseCancel(address _market, uint256 id) external onlyMakerOrMarket(_market) {
        IMarket(_market).closeCancel(msg.sender, id);
    }

    function priceToOpen(
        address _market,
        uint256 id,
        uint256 price,
        uint256 indexPrice,
        uint256 indexPriceTimestamp
    ) external onlyPriceProvider onlyMakerOrMarket(_market) {
        IMarket(_market).priceToOpen(id, price, indexPrice, indexPriceTimestamp);
        emit Open(_market, id);
    }

    function priceToClose(
        address _market,
        uint256 id,
        uint256 price,
        uint256 indexPrice,
        uint256 indexPriceTimestamp
    ) external onlyPriceProvider onlyMakerOrMarket(_market)
    {
        IMarket(_market).priceToClose(id, price, indexPrice, indexPriceTimestamp);
        emit Close(_market, id);
    }

    function depositMargin(address _market, uint256 _id, uint256 _value) external onlyMakerOrMarket(_market) {
        IMarket(_market).depositMargin(msg.sender, _id, _value);
        emit DepositMargin(_market, _id);
    }

    function priceToOpenCancel(address _market, uint256 id) external onlyPriceProvider onlyMakerOrMarket(_market) {
        IMarket(_market).priceToOpenCancel(id);
        emit Cancel(_market, id);
    }

    function priceToCloseCancel(address _market, uint256 id) external onlyPriceProvider onlyMakerOrMarket(_market) {
        IMarket(_market).priceToCloseCancel(id);
    }

    function priceToLiquidity(
        address _market,
        uint256 id,
        uint256 price,
        uint256 indexPrice,
        uint256 indexPriceTimestamp
    ) external onlyPriceProvider onlyMakerOrMarket(_market) {
        IMarket(_market).liquidity(id, price, indexPrice, indexPriceTimestamp);
        emit Close(_market, id);
    }

    function marketTakerOrderList(address _market, address taker) external view returns (uint256[] memory) {
        return IMarket(_market).getTakerOrderlist(taker);
    }

    function getMarketOrderByID(address _market, uint256 id) external view returns (bytes memory) {
        return IMarket(_market).getByID(id);
    }

    //maker
    function addLiquidity(address _makerAddress, uint _amount, uint _deadline) external ensure(_deadline) onlyMakerOrMarket(_makerAddress) returns (bool){
        (uint _id, address _maker, uint _value, uint _cancelDeadline) = IMaker(_makerAddress).addLiquidity(msg.sender, _amount);
        emit AddLiquidity(_id, _maker, _value, _cancelDeadline);
        return true;
    }

    function cancelAddLiquidity(address _makerAddress, uint _id) external onlyMakerOrMarket(_makerAddress) returns (uint _amount){
        (_amount) = IMaker(_makerAddress).cancelAddLiquidity(msg.sender, _id);
        emit CancelAddLiquidity(_id, _makerAddress);
    }

    function priceToAddLiquidity(address _makerAddress, uint256 _id, uint256 _price, uint256 _priceTimestamp) external onlyPriceProvider onlyMakerOrMarket(_makerAddress) returns (uint _liquidity){
        (_liquidity) = IMaker(_makerAddress).priceToAddLiquidity(_id, _price, _priceTimestamp);
        emit PriceToAddLiquidity(_id, _makerAddress);
    }

    function removeLiquidity(address _makerAddress, uint _liquidity, uint _deadline) external ensure(_deadline) onlyMakerOrMarket(_makerAddress) returns (bool){
        (uint _id, address _maker, uint _value,uint _cancelDeadline) = IMaker(_makerAddress).removeLiquidity(msg.sender, _liquidity);
        emit RemoveLiquidity(_id, _maker, _value, _cancelDeadline);
        return true;
    }

    function priceToRemoveLiquidity(address _makerAddress, uint _id, uint _price, uint _priceTimestamp) external onlyPriceProvider onlyMakerOrMarket(_makerAddress) returns (uint _amount){
        (_amount) = IMaker(_makerAddress).priceToRemoveLiquidity(_id, _price, _priceTimestamp);
        emit PriceToRemoveLiquidity(_id, _makerAddress);
    }

    function cancelRemoveLiquidity(address _makerAddress, uint _id) external onlyMakerOrMarket(_makerAddress) returns (bool){
        IMaker(_makerAddress).cancelRemoveLiquidity(msg.sender, _id);
        emit CancelRemoveLiquidity(_id, _makerAddress);
        return true;
    }

    function systemCancelAddLiquidity(address _makerAddress, uint _id) external onlyPriceProvider onlyMakerOrMarket(_makerAddress) {
        IMaker(_makerAddress).systemCancelAddLiquidity(_id);
    }

    function systemCancelRemoveLiquidity(address _makerAddress, uint _id) external onlyPriceProvider onlyMakerOrMarket(_makerAddress) {
        IMaker(_makerAddress).systemCancelRemoveLiquidity(_id);
    }

    function getMakerOrderIds(address _makerAddress, address _taker) external view returns (uint[] memory _orderIds){
        (_orderIds) = IMaker(_makerAddress).getMakerOrderIds(_taker);
    }

    function getPoolOrder(address _makerAddress, uint _no) external view returns (bytes memory _order){
        (_order) = IMaker(_makerAddress).getOrder(_no);
    }

    function getLpBalanceOf(address _makerAddress, address _taker) external view returns (uint _liquidity, uint _totalSupply){
        (_liquidity, _totalSupply) = IMaker(_makerAddress).getLpBalanceOf(_taker);
    }

    function canOpen(address _makerAddress, uint _makerMargin) external view returns (bool){
        return IMaker(_makerAddress).canOpen(_makerMargin);
    }

    function canRemoveLiquidity(address _makerAddress, uint _price, uint _liquidity) external view returns (bool){
        return IMaker(_makerAddress).canRemoveLiquidity(_price, _liquidity);
    }

    function canAddLiquidity(address _makerAddress, uint _price) external view returns (bool){
        return IMaker(_makerAddress).canAddLiquidity(_price);
    }
}

