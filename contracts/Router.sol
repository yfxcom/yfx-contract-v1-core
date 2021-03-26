pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IMarket.sol";
import "./interface/IMaker.sol";
import './interface/IManager.sol';
import './library/SignatureDecode.sol';

contract Router {
    address manager;

    string public constant name = "YFX";
    string public constant version = "1";
    // EIP712 niceties
    bytes32 public DOMAIN_SEPARATOR;

    // bytes32 public constant TAKEROPEN_TYPEHASH = 'TakerOpenPermit(address sender,address market,address inviter,uint128 minPrice,uint128 maxPrice,uint256 margin,uint16 leverage,int8 direction,uint256 deadline,uint256 nonce)'
    bytes32 public constant TAKEROPEN_TYPEHASH = 0xa913604615dad4d8cfb0d484255ed2a52052a2ffdc8ebbef3a7aca3f7f41de8e;

    // bytes32 public constant TAKERCLOSE_TYPEHASH = 'TakerClosePermit(address sender,address market,uint256 id,uint128 minPrice,uint128 maxPrice,uint256 deadline,uint256 nonce)'
    bytes32 public constant TAKERCLOSE_TYPEHASH = 0xed81554ea1691880ebd7a687569fd429508995119fc5eca68e1f99f539783a60;

    // bytes32 public constant TAKEROPENCANCEl_TYPEHASH = 'TakerOpenCancelPermit(address sender,address market,uint256 id,uint256 nonce)'
    bytes32 public constant TAKEROPENCANCEL_TYPEHASH = 0x03f0f15ceebaaed647c0db4a821b1a5c92d9db5661b44f19c5833573a7551ec8;

    // bytes32 public constant TAKERCLOSECANCEL_TYPEHASH = 'TakerCloseCancelPermit(address sender,address market,uint256 id,uint256 nonce)'
    bytes32 public constant TAKERCLOSECANCEL_TYPEHASH = 0x92d0304770691a5590b277616a734188b97c678987ed8accee8baebaac548821;

    // bytes32 public constant TAKERDEPOSITMARGIN_TYPEHASH = 'DepositMarginPermit(address sender,address market,uint256 id,uint256 value,uint256 nonce)'
    bytes32 public constant TAKERDEPOSITMARGIN_TYPEHASH = 0xb412837942b6c6cfaf97c18936bae122cf7dadda27542f77111c3a710b0b5635;

    //bytes32 public constant ADDLIQUIDITY_TYPEHASH = 'AddLiquidityPermit(address sender,address makerAddress,uint amount,uint deadline,uint256 nonce)'
    bytes32 public constant ADDLIQUIDITY_TYPEHASH = 0x5a742ab2d0b60058f5f9b919b96b2d4430cadffb80ab10afa4a2b144b0df755c;

    //bytes32 public constant CANCELADDLIQUIDITY_TYPEHASH = 'CancelAddLiquidityPermit(address sender,address makerAddress,uint id,uint256 nonce)'
    bytes32 public constant CANCELADDLIQUIDITY_TYPEHASH = 0x62310cbde59ffad1d900c90f8393f5e9d366a766d3a03f1a9f2f0de53b95214e;

    //bytes32 public constant REMOVELIQUIDITY_TYPEHASH = 'RemoveLiquidityPermit(address sender,address makerAddress,uint liquidity,uint deadline,uint256 nonce)'
    bytes32 public constant REMOVELIQUIDITY_TYPEHASH = 0xbd3a66294dbe2650de2d59a79ea1fada49da6c8d82df602f409944e025713e78;

    //bytes32 public constant CANCELREMOVELIQUIDITY_TYPEHASH = 'CancelRemoveLiquidityPermit(address sender,address makerAddress,uint id,uint256 nonce)'
    bytes32 public constant CANCELREMOVELIQUIDITY_TYPEHASH = 0x2da79292e8a20c3843e8427fd517b7120b69b704c0069557732ff1069a80ff3f;

    mapping(address => uint256) public nonces;

    struct AddLiquidityParams {
        address _sender;
        address _makerAddress;
        uint _amount;
        uint _deadline;
        uint256 _nonce;
    }

    struct RemoveLiquidityParams {
        address _sender;
        address _makerAddress;
        uint _liquidity;
        uint _deadline;
        uint256 _nonce;
    }

    struct TakerCloseParams {
        address _sender;
        address _market;
        uint256 id;
        uint128 minPrice;
        uint128 maxPrice;
        uint256 deadline;
        uint256 _nonce;
    }

    struct TakerOpenParams {
        address _sender;
        address _market;
        address inviter;
        uint128 minPrice;
        uint128 maxPrice;
        uint256 margin;
        uint16 leverage;
        int8 direction;
        uint256 deadline;
        uint256 _nonce;
        uint256 id;
    }

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

    constructor(address _manager, uint256 chainId) public {
        require(_manager != address(0), "Router:constructor _manager is zero address");
        manager = _manager;

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
        uint256 id = IMarket(_market).open(msg.sender, inviter, minPrice, maxPrice, margin, uint16(leverage), direction);
        emit TakerOpen(_market, id);
    }

    /*
       addressValues sort：
           address _sender,
           address _market,
           address _invite

       uintValues sort：
           uint128 minPrice,
           uint128 maxPrice,
           uint256 margin,
           uint16 leverage,
           uint256 deadline,
           uint256 _nonce
       */
    function takerOpenPermit(
        address[] calldata addressValues,
        uint256[] calldata uintValues,
        int8 direction,
        bytes calldata _sign
    ) external ensure(uintValues[4]) onlyMakerOrMarket(addressValues[1]) {
        TakerOpenParams memory params = TakerOpenParams(
            addressValues[0],
            addressValues[1],
            addressValues[2],
            uint128(uintValues[0]),
            uint128(uintValues[1]),
            uintValues[2],
            uint16(uintValues[3]),
            direction,
            uintValues[4],
            uintValues[5],
            0
        );
        require(verify(params._sender, params._nonce, keccak256(abi.encode(TAKEROPEN_TYPEHASH, params._sender, params._market, params.inviter, params.minPrice, params.maxPrice, params.margin, params.leverage, params.direction, params.deadline, params._nonce)), _sign), 'verify error');

        params.id = IMarket(params._market).open(params._sender, params.inviter, params.minPrice, params.maxPrice, params.margin, params.leverage, params.direction);
        emit TakerOpen(params._market, params.id);
    }

    function takerClose(address _market, uint256 id, uint128 minPrice, uint128 maxPrice, uint256 deadline) external ensure(deadline) onlyMakerOrMarket(_market) {
        IMarket(_market).close(msg.sender, id, minPrice, maxPrice);
        emit TakerClose(_market, id);
    }

    function takerClosePermit(address _sender, address _market, uint256 id, uint128 minPrice, uint128 maxPrice, uint256 deadline, uint256 _nonce, bytes calldata _sign) external ensure(deadline) onlyMakerOrMarket(_market) {
        TakerCloseParams memory params = TakerCloseParams(
            _sender,
            _market,
            id,
            minPrice,
            maxPrice,
            deadline,
            _nonce
        );
        require(verify(_sender, _nonce, keccak256(abi.encode(TAKERCLOSE_TYPEHASH, params._sender, params._market, params.id, params.minPrice, params.maxPrice, params.deadline, params._nonce)), _sign), 'verify error');

        IMarket(params._market).close(params._sender, params.id, params.minPrice, params.maxPrice);
        emit TakerClose(params._market, params.id);
    }

    function takerOpenCancel(address _market, uint256 id) external onlyMakerOrMarket(_market) {
        IMarket(_market).openCancel(msg.sender, id);
        emit Cancel(_market, id);
    }

    function takerOpenCancelPermit(address _sender, address _market, uint256 id, uint256 _nonce, bytes calldata _sign) external onlyMakerOrMarket(_market) {
        require(verify(_sender, _nonce, keccak256(abi.encode(TAKEROPENCANCEL_TYPEHASH, _sender, _market, id, _nonce)), _sign), 'verify error');

        IMarket(_market).openCancel(_sender, id);
        emit Cancel(_market, id);
    }

    function takerCloseCancel(address _market, uint256 id) external onlyMakerOrMarket(_market) {
        IMarket(_market).closeCancel(msg.sender, id);
    }

    function takerCloseCancelPermit(address _sender, address _market, uint256 id, uint256 _nonce, bytes calldata _sign) external onlyMakerOrMarket(_market) {
        require(verify(_sender, _nonce, keccak256(abi.encode(TAKERCLOSECANCEL_TYPEHASH, _sender, _market, id, _nonce)), _sign), 'verify error');

        IMarket(_market).closeCancel(_sender, id);
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

    function depositMarginPermit(address _sender, address _market, uint256 _id, uint256 _value, uint256 _nonce, bytes calldata _sign) external onlyMakerOrMarket(_market) {
        require(verify(_sender, _nonce, keccak256(abi.encode(TAKERDEPOSITMARGIN_TYPEHASH, _sender, _market, _id, _value, _nonce)), _sign), 'verify error');

        IMarket(_market).depositMargin(_sender, _id, _value);
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

    function addLiquidityPermit(address _sender, address _makerAddress, uint _amount, uint _deadline, uint256 _nonce, bytes calldata _sign) external ensure(_deadline) onlyMakerOrMarket(_makerAddress) returns (bool){
        AddLiquidityParams memory params = AddLiquidityParams(
            _sender,
            _makerAddress,
            _amount,
            _deadline,
            _nonce
        );
        require(verify(_sender, _nonce, keccak256(abi.encode(ADDLIQUIDITY_TYPEHASH, params._sender, params._makerAddress, params._amount, params._deadline, params._nonce)), _sign), 'verify error');

        (uint _id, address _maker, uint _value, uint _cancelDeadline) = IMaker(params._makerAddress).addLiquidity(params._sender, params._amount);
        emit AddLiquidity(_id, _maker, _value, _cancelDeadline);
        return true;
    }

    function cancelAddLiquidity(address _makerAddress, uint _id) external onlyMakerOrMarket(_makerAddress) returns (uint _amount){
        (_amount) = IMaker(_makerAddress).cancelAddLiquidity(msg.sender, _id);
        emit CancelAddLiquidity(_id, _makerAddress);
    }

    function cancelAddLiquidityPermit(address _sender, address _makerAddress, uint _id, uint256 _nonce, bytes calldata _sign) external onlyMakerOrMarket(_makerAddress) returns (uint _amount){
        require(verify(_sender, _nonce, keccak256(abi.encode(CANCELADDLIQUIDITY_TYPEHASH, _sender, _makerAddress, _id, _nonce)), _sign), 'verify error');

        (_amount) = IMaker(_makerAddress).cancelAddLiquidity(_sender, _id);
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

    function removeLiquidityPermit(address _sender, address _makerAddress, uint _liquidity, uint _deadline, uint256 _nonce, bytes calldata _sign) external ensure(_deadline) onlyMakerOrMarket(_makerAddress) returns (bool){
        RemoveLiquidityParams memory params = RemoveLiquidityParams(
            _sender,
            _makerAddress,
            _liquidity,
            _deadline,
            _nonce
        );
        require(verify(_sender, _nonce, keccak256(abi.encode(REMOVELIQUIDITY_TYPEHASH, params._sender, params._makerAddress, params._liquidity, params._deadline, params._nonce)), _sign), 'verify error');

        (uint _id, address _maker, uint _value,uint _cancelDeadline) = IMaker(params._makerAddress).removeLiquidity(params._sender, params._liquidity);
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

    function cancelRemoveLiquidityPermit(address _sender, address _makerAddress, uint _id, uint256 _nonce, bytes calldata _sign) external onlyMakerOrMarket(_makerAddress) returns (bool){
        require(verify(_sender, _nonce, keccak256(abi.encode(CANCELREMOVELIQUIDITY_TYPEHASH, _sender, _makerAddress, _id, _nonce)), _sign), 'verify error');

        IMaker(_makerAddress).cancelRemoveLiquidity(_sender, _id);
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

    function verify(address _sender, uint256 _nonce, bytes32 _data, bytes memory _sign) internal returns (bool) {
        require(_sender != address(0));
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                _data
            )
        );
        (bytes32 _r, bytes32 _s,uint8 _v) = SignatureDecode.decode(_sign);
        require(_nonce == nonces[_sender]++);
        return _sender == ecrecover(digest, _v, _r, _s);
    }
}

