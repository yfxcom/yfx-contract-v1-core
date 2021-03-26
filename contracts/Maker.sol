pragma solidity >=0.5.15  <=0.5.17;

import './library/SafeMath.sol';
import './library/SignedSafeMath.sol';
import './interface/IMaker.sol';
import './ERC20Permit.sol';
import './library/TransferHelper.sol';
import './interface/IMarket.sol';
import './interface/IUser.sol';
import './interface/IManager.sol';
import './interface/IERC20.sol';
import './library/Bytes.sol';
import "./library/Types.sol";
import "./library/ReentrancyGuard.sol";

contract Maker is IMaker, ERC20Permit, ReentrancyGuard {
    using SafeMath for uint;
    using SignedSafeMath for int;

    uint public makerAutoId = 1;
    uint public indexPrice;

    address public market;
    address public manager;

    uint256 public balance;
    uint256 public makerLock;
    uint256 public sharePrice;

    uint256 public longAmount;
    uint256 public longMargin;
    uint256 public longOpenTotal;

    uint256 public shortAmount;
    uint256 public shortMargin;
    uint256 public shortOpenTotal;

    uint256 public takerTotalMargin;

    address public clearAnchorAddress;
    address public userAddress;
    uint public clearAnchorDecimals;
    uint256 public constant priceDecimals = 10;
    uint256 public constant amountDecimals = 10;
    uint256 public constant sharePriceDecimals = 20;
    uint public marketType;
    //the rate is x/10000
    uint public openRate = 5000;
    //the rate is x/1000000
    uint public removeLiquidityRate = 1000;
    uint public minAddLiquidityAmount;
    uint public minRemoveLiquidity;
    //
    int256 public rlzPNL;
    uint public feeToMaker;

    mapping(uint => Types.MakerOrder) makerOrders;
    mapping(address => uint[]) public makerOrderIds;
    mapping(address => uint) public lockBalanceOf;

    bool public addPaused = true;
    bool public removePaused = true;

    constructor(address _manager, uint256 chainId) public ERC20Permit(chainId) {
        require(_manager != address(0), "Maker:constructor _manager is zero address");
        manager = _manager;
    }

    modifier _onlyMarket(){
        require(msg.sender == market, 'Caller is not market');
        _;
    }

    modifier _onlyRouter(){
        require(IManager(manager).checkRouter(msg.sender), 'only router');
        _;
    }

    modifier _onlyManager(){
        require(IManager(manager).checkController(msg.sender), 'only manage');
        _;
    }

    modifier whenNotAddPaused() {
        require(!IManager(manager).paused() && !addPaused, "paused");
        _;
    }

    modifier whenNotRemovePaused() {
        require(!IManager(manager).paused() && !removePaused, "paused");
        _;
    }

    function initialize(
        uint _indexPrice,
        address _clearAnchorAddress,
        address _market,
        uint _marketType,
        string calldata _lpTokenName
    ) external returns (bool){
        require(msg.sender == manager, 'Caller is not manager');
        require(_clearAnchorAddress != address(0), "Maker:initialize _clearAnchorAddress is zero address");
        require(_market != address(0), "Maker:initialize _market is zero address");
        indexPrice = _indexPrice;
        clearAnchorAddress = _clearAnchorAddress;
        market = _market;
        marketType = _marketType;
        name = _lpTokenName;
        symbol = _lpTokenName;
        clearAnchorDecimals = IERC20(clearAnchorAddress).decimals();
        userAddress = IManager(manager).taker();
        return true;
    }

    function getOrder(uint _no) external view returns (bytes memory _order){
        require(makerOrders[_no].id != 0, "not exist");
        bytes memory _order1 = abi.encode(
            makerOrders[_no].id,
            makerOrders[_no].maker,
            makerOrders[_no].submitBlockHeight,
            makerOrders[_no].submitBlockTimestamp,
            makerOrders[_no].price,
            makerOrders[_no].priceTimestamp,
            makerOrders[_no].amount,
            makerOrders[_no].liquidity,
            makerOrders[_no].feeToPool,
            makerOrders[_no].cancelBlockHeight);
        bytes memory _order2 = abi.encode(
            makerOrders[_no].sharePrice,
            makerOrders[_no].poolTotal,
            makerOrders[_no].profit,
            makerOrders[_no].action,
            makerOrders[_no].status);

        _order = Bytes.contact(_order1, _order2);
    }

    function open(uint _value) external nonReentrant _onlyMarket returns (bool){
        require(this.canOpen(_value), 'Insufficient pool balance');
        uint preTotal = balance.add(makerLock);
        balance = balance.sub(_value);
        makerLock = makerLock.add(_value);
        TransferHelper.safeTransfer(clearAnchorAddress, market, _value);
        assert(preTotal == balance.add(makerLock));
        return true;
    }

    function openUpdate(
        uint _makerMargin,
        uint _takerMargin,
        uint _amount,
        uint _total,
        int8 _takerDirection
    ) external nonReentrant _onlyMarket returns (bool){
        require(_makerMargin > 0 && _takerMargin > 0 && _amount > 0 && _total > 0, 'can not zero');
        require(_takerDirection == 1 || _takerDirection == - 1, 'takerDirection is invalid');
        takerTotalMargin = takerTotalMargin.add(_takerMargin);
        if (_takerDirection == 1) {
            longAmount = longAmount.add(_amount);
            longMargin = longMargin.add(_makerMargin);
            longOpenTotal = longOpenTotal.add(_total);
        } else {
            shortAmount = shortAmount.add(_amount);
            shortMargin = shortMargin.add(_makerMargin);
            shortOpenTotal = shortOpenTotal.add(_total);
        }
        return true;
    }

    function closeUpdate(
        uint _makerMargin,
        uint _takerMargin,
        uint _amount,
        uint _total,
        int makerProfit,
        uint makerFee,
        int8 _takerDirection
    ) external nonReentrant _onlyMarket returns (bool){
        require(_makerMargin > 0 && _takerMargin > 0 && _amount > 0 && _total > 0, 'can not zero');
        require(makerLock >= _makerMargin, 'makerMargin is invalid');
        require(_takerDirection == 1 || _takerDirection == - 1, 'takerDirection is invalid');
        makerLock = makerLock.sub(_makerMargin);
        balance = balance.add(makerFee);
        feeToMaker = feeToMaker.add(makerFee);
        rlzPNL = rlzPNL.add(makerProfit);
        int256 tempProfit = makerProfit.add(int(_makerMargin));
        require(tempProfit >= 0, 'tempProfit is invalid');
        balance = uint(tempProfit.add(int256(balance)));
        require(takerTotalMargin >= _takerMargin, 'takerMargin is invalid');
        takerTotalMargin = takerTotalMargin.sub(_takerMargin);
        if (_takerDirection == 1) {
            require(longAmount >= _amount && longMargin >= _makerMargin && longOpenTotal >= _total, 'long data error');
            longAmount = longAmount.sub(_amount);
            longMargin = longMargin.sub(_makerMargin);
            longOpenTotal = longOpenTotal.sub(_total);
        } else {
            require(shortAmount >= _amount && shortMargin >= _makerMargin && shortOpenTotal >= _total, 'short data error');
            shortAmount = shortAmount.sub(_amount);
            shortMargin = shortMargin.sub(_makerMargin);
            shortOpenTotal = shortOpenTotal.sub(_total);
        }
        return true;
    }

    function takerDepositMarginUpdate(uint _margin) external nonReentrant _onlyMarket returns (bool){
        require(_margin > 0, 'can not zero');
        require(takerTotalMargin > 0, 'empty position');
        takerTotalMargin = takerTotalMargin.add(_margin);
        return true;
    }

    function addLiquidity(
        address sender,
        uint amount
    ) external nonReentrant _onlyRouter whenNotAddPaused returns (
        uint _id,
        address _makerAddress,
        uint _amount,
        uint _cancelBlockElapse
    ){
        require(sender != address(0), "Maker:addLiquidity sender is zero address");
        require(amount >= minAddLiquidityAmount, 'amount < minAddLiquidityAmount');
        (bool isSuccess) = IUser(userAddress).transfer(clearAnchorAddress, sender, amount);
        require(isSuccess, 'transfer fail');
        makerOrders[makerAutoId] = Types.MakerOrder(
            makerAutoId,
            sender,
            block.number,
            block.timestamp,
            0,
            0,
            amount,
            0,
            0,
            0,
            sharePrice,
            0,
            0,
            Types.PoolAction.Deposit,
            Types.PoolActionStatus.Submit
        );
        makerOrders[makerAutoId].cancelBlockHeight = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        _id = makerOrders[makerAutoId].id;
        _makerAddress = address(this);
        _amount = makerOrders[makerAutoId].amount;
        _cancelBlockElapse = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        makerOrderIds[sender].push(makerAutoId);
        makerAutoId = makerAutoId.add(1);
    }

    function cancelAddLiquidity(
        address sender,
        uint id
    ) external nonReentrant _onlyRouter returns (uint _amount){
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.maker == sender, 'Caller is not order owner');
        require(order.action == Types.PoolAction.Deposit, 'not deposit');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        require(block.number > order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Can not cancel');
        order.status = Types.PoolActionStatus.Cancel;
        IUser(userAddress).receiveToken(clearAnchorAddress, order.maker, order.amount);
        TransferHelper.safeTransfer(clearAnchorAddress, userAddress, order.amount);
        _amount = order.amount;
        //makerOrders[id] = order;
    }

    function priceToAddLiquidity(
        uint256 id,
        uint256 price,
        uint256 priceTimestamp
    ) external nonReentrant _onlyRouter returns (uint liquidity){
        // require(price > 0, 'Price is not zero');
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(block.number < order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Time out');
        require(order.action == Types.PoolAction.Deposit, 'not deposit');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        order.status = Types.PoolActionStatus.Success;
        int totalUnPNL;
        if (balance.add(makerLock) > 0 && totalSupply > 0) {
            (totalUnPNL) = this.makerProfit(price);
            require(totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock), 'taker or maker is broken');
            liquidity = order.amount.mul(totalSupply).div(uint(totalUnPNL.add(int(makerLock)).add(int(balance))));
        } else {
            sharePrice = 10 ** sharePriceDecimals;
            liquidity = order.amount.mul(10 ** decimals).div(10 ** clearAnchorDecimals);
        }
        _mint(order.maker, liquidity);
        balance = balance.add(order.amount);
        order.poolTotal = int(balance).add(int(makerLock)).add(totalUnPNL);
        sharePrice = uint(order.poolTotal).mul(10 ** decimals).mul(10 ** sharePriceDecimals).div(totalSupply).div(10 ** clearAnchorDecimals);
        order.price = price;
        order.profit = rlzPNL.add(int(feeToMaker)).add(totalUnPNL);
        order.liquidity = liquidity;
        order.sharePrice = sharePrice;
        order.priceTimestamp = priceTimestamp;
        //makerOrders[id] = order;
    }

    function removeLiquidity(
        address sender,
        uint liquidity
    ) external nonReentrant _onlyRouter whenNotRemovePaused returns (
        uint _id,
        address _makerAddress,
        uint _liquidity,
        uint _cancelBlockElapse
    ){
        require(sender != address(0), "Maker:removeLiquidity sender is zero address");
        require(liquidity >= minRemoveLiquidity, 'liquidity < minRemoveLiquidity');
        require(balanceOf[sender] >= liquidity, 'Insufficient balance');
        balanceOf[sender] = balanceOf[sender].sub(liquidity);
        lockBalanceOf[sender] = lockBalanceOf[sender].add(liquidity);
        makerOrders[makerAutoId] = Types.MakerOrder(
            makerAutoId,
            sender,
            block.number,
            block.timestamp,
            0,
            0,
            0,
            liquidity,
            0,
            0,
            sharePrice,
            0,
            0,
            Types.PoolAction.Withdraw,
            Types.PoolActionStatus.Submit
        );
        makerOrders[makerAutoId].cancelBlockHeight = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        _id = makerOrders[makerAutoId].id;
        _makerAddress = address(this);
        _liquidity = makerOrders[makerAutoId].liquidity;
        _cancelBlockElapse = makerOrders[makerAutoId].submitBlockHeight.add(IManager(manager).cancelBlockElapse());
        makerOrderIds[sender].push(makerAutoId);
        makerAutoId = makerAutoId.add(1);
    }

    function cancelRemoveLiquidity(address sender, uint id) external nonReentrant _onlyRouter returns (bool){
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.maker == sender, 'Caller is not sender');
        require(order.action == Types.PoolAction.Withdraw, 'not withdraw');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        require(block.number > order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Can not cancel');
        order.status = Types.PoolActionStatus.Cancel;
        lockBalanceOf[sender] = lockBalanceOf[sender].sub(order.liquidity);
        balanceOf[sender] = balanceOf[sender].add(order.liquidity);
        //makerOrders[id] = order;
        return true;
    }

    function systemCancelAddLiquidity(uint id) external nonReentrant _onlyRouter {
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.action == Types.PoolAction.Deposit, 'not deposit');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        order.status = Types.PoolActionStatus.Fail;
        IUser(userAddress).receiveToken(clearAnchorAddress, order.maker, order.amount);
        TransferHelper.safeTransfer(clearAnchorAddress, userAddress, order.amount);
    }

    function systemCancelRemoveLiquidity(uint id) external nonReentrant _onlyRouter {
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(order.action == Types.PoolAction.Withdraw, 'not withdraw');
        require(order.status == Types.PoolActionStatus.Submit, 'not submit');
        order.status = Types.PoolActionStatus.Fail;
        lockBalanceOf[order.maker] = lockBalanceOf[order.maker].sub(order.liquidity);
        balanceOf[order.maker] = balanceOf[order.maker].add(order.liquidity);
    }

    function priceToRemoveLiquidity(
        uint id,
        uint price,
        uint priceTimestamp
    ) external nonReentrant _onlyRouter returns (uint amount){
        require(price > 0 && totalSupply > 0 && balance.add(makerLock) > 0, 'params is invalid');
        Types.MakerOrder storage order = makerOrders[id];
        require(order.id != 0, 'not exist');
        require(block.number < order.submitBlockHeight.add(IManager(manager).cancelBlockElapse()), 'Time out');
        require(order.action == Types.PoolAction.Withdraw, 'not withdraw');
        require(order.status == Types.PoolActionStatus.Submit && totalSupply >= order.liquidity, 'not submit');
        order.status = Types.PoolActionStatus.Success;
        (int totalUnPNL) = this.makerProfit(price);
        require(totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock), 'taker or maker is broken');
        amount = order.liquidity.mul(uint(int(makerLock).add(int(balance)).add(totalUnPNL))).div(totalSupply);
        require(amount > 0, 'amount is zero');
        require(balance >= amount, 'Insufficient balance');
        balance = balance.sub(amount);
        balanceOf[order.maker] = balanceOf[order.maker].add(order.liquidity);
        lockBalanceOf[order.maker] = lockBalanceOf[order.maker].sub(order.liquidity);
        _burn(order.maker, order.liquidity);
        order.amount = amount.mul(uint(1000000).sub(removeLiquidityRate)).div(1000000);
        require(order.amount > 0, 'order.amount is zero');
        order.feeToPool = amount.sub(order.amount);
        IUser(userAddress).receiveToken(clearAnchorAddress, order.maker, order.amount);
        TransferHelper.safeTransfer(clearAnchorAddress, userAddress, order.amount);
        require(IManager(manager).poolFeeOwner() != address(0), 'poolFee is zero address');
        if (order.feeToPool > 0) {
            TransferHelper.safeTransfer(clearAnchorAddress, IManager(manager).poolFeeOwner(), order.feeToPool);
        }
        order.poolTotal = int(balance).add(int(makerLock)).add(totalUnPNL);
        if (totalSupply > 0) {
            sharePrice = uint(order.poolTotal).mul(10 ** decimals).mul(10 ** sharePriceDecimals).div(totalSupply).div(10 ** clearAnchorDecimals);
        } else {
            sharePrice = 10 ** sharePriceDecimals;
        }
        order.price = price;
        order.profit = rlzPNL.add(int(feeToMaker)).add(totalUnPNL);
        order.sharePrice = sharePrice;
        order.priceTimestamp = priceTimestamp;
        //makerOrders[id] = order;
    }

    function makerProfit(uint256 _price) external view returns (int256 unPNL){
        require(marketType == 0 || marketType == 1 || marketType == 2, 'marketType is invalid');
        int256 shortUnPNL = 0;
        int256 longUnPNL = 0;
        if (marketType == 1) {//rervese
            int256 closeLongTotal = int256(longAmount.mul(10 ** priceDecimals).mul(10 ** clearAnchorDecimals).div(_price).div(10 ** amountDecimals));
            int256 openLongTotal = int256(longOpenTotal);
            longUnPNL = (openLongTotal.sub(closeLongTotal)).mul(- 1);

            int256 closeShortTotal = int256(shortAmount.mul(10 ** priceDecimals).mul(10 ** clearAnchorDecimals).div(_price).div(10 ** amountDecimals));
            int256 openShortTotal = int256(shortOpenTotal);
            shortUnPNL = openShortTotal.sub(closeShortTotal);

            unPNL = shortUnPNL.add(longUnPNL);
        } else {
            int256 closeLongTotal = int256(longAmount.mul(_price).mul(10 ** clearAnchorDecimals).div(10 ** priceDecimals).div(10 ** amountDecimals));
            int256 openLongTotal = int256(longOpenTotal);
            longUnPNL = (closeLongTotal.sub(openLongTotal)).mul(- 1);

            int256 closeShortTotal = int256(shortAmount.mul(_price).mul(10 ** clearAnchorDecimals).div(10 ** priceDecimals).div(10 ** amountDecimals));
            int256 openShortTotal = int256(shortOpenTotal);
            shortUnPNL = closeShortTotal.sub(openShortTotal);

            unPNL = shortUnPNL.add(longUnPNL);
            if (marketType == 2) {
                unPNL = unPNL.mul(int(IMarket(market).clearAnchorRatio())).div(int(10 ** IMarket(market).clearAnchorRatioDecimals()));
            }
        }
    }

    function updateSharePrice(uint price) external view returns (
        uint _price,
        uint256 _balance,
        uint256 _makerLock,
        uint256 _feeToMaker,

        uint256 _longAmount,
        uint256 _longMargin,
        uint256 _longOpenTotal,

        uint256 _shortAmount,
        uint256 _shortMargin,
        uint256 _shortOpenTotal
    ){
        require(price > 0, 'params is invalid');
        (int totalUnPNL) = this.makerProfit(price);
        require(totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock), 'taker or maker is broken');
        if (totalSupply > 0) {
            _price = uint(totalUnPNL.add(int(makerLock)).add(int(balance))).mul(10 ** decimals).mul(10 ** sharePriceDecimals).div(totalSupply).div(10 ** clearAnchorDecimals);
        } else {
            _price = 10 ** sharePriceDecimals;
        }
        _balance = balance;
        _makerLock = makerLock;
        _feeToMaker = feeToMaker;

        _longAmount = longAmount;
        _longMargin = longMargin;
        _longOpenTotal = longOpenTotal;

        _shortAmount = shortAmount;
        _shortMargin = shortMargin;
        _shortOpenTotal = shortOpenTotal;
    }

    function setMinAddLiquidityAmount(uint _minAmount) external _onlyManager returns (bool){
        minAddLiquidityAmount = _minAmount;
        return true;
    }

    function setMinRemoveLiquidity(uint _minLiquidity) external _onlyManager returns (bool){
        minRemoveLiquidity = _minLiquidity;
        return true;
    }

    function setOpenRate(uint _openRate) external _onlyManager returns (bool){
        openRate = _openRate;
        return true;
    }

    function setRemoveLiquidityRate(uint _rate) external _onlyManager returns (bool){
        removeLiquidityRate = _rate;
        return true;
    }

    function setPaused(bool _add, bool _remove) external _onlyManager {
        addPaused = _add;
        removePaused = _remove;
    }

    function getMakerOrderIds(address _maker) external view returns (uint[] memory){
        return makerOrderIds[_maker];
    }

    function canOpen(uint _makerMargin) external view returns (bool _can){
        if (balance > _makerMargin) {
            uint rate = (makerLock.add(_makerMargin)).mul(10000).div(balance.add(makerLock));
            _can = (rate <= openRate) ? true : false;
        } else {
            _can = false;
        }
    }

    function canRemoveLiquidity(uint _price, uint _liquidity) external view returns (bool){
        if (_price > 0 && totalSupply > 0) {
            (int totalUnPNL) = this.makerProfit(_price);
            if (totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock)) {
                uint amount = _liquidity.mul(uint(int(makerLock).add(int(balance)).add(totalUnPNL))).div(totalSupply);
                if (balance >= amount) {
                    return true;
                }
            }
        }
        return false;
    }

    function canAddLiquidity(uint _price) external view returns (bool){
        (int totalUnPNL) = this.makerProfit(_price);
        if (totalUnPNL <= int(takerTotalMargin) && totalUnPNL * (- 1) <= int(makerLock)) {
            return true;
        }
        return false;
    }

    function getLpBalanceOf(address _maker) external view returns (uint _balance, uint _totalSupply){
        _balance = balanceOf[_maker];
        _totalSupply = totalSupply;
    }

    function getChainId() external view returns (uint256){
        return chainId;
    }
}
