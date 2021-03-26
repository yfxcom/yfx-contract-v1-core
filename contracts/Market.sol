pragma solidity >=0.5.15  <=0.5.17;

import "./interface/IUser.sol";
import "./interface/IMaker.sol";
import "./interface/IMarket.sol";
import "./interface/IERC20.sol";
import "./interface/IManager.sol";
import "./library/SafeMath.sol";
import "./library/SignedSafeMath.sol";
import "./library/TransferHelper.sol";
import "./library/Types.sol";
import "./library/Bytes.sol";
import "./library/ReentrancyGuard.sol";

contract Market is IMarket, ReentrancyGuard {
    using SafeMath for uint;
    using SignedSafeMath for int;

    uint8 public marketType = 0;

    uint32 public insertID;
    mapping(uint256 => Types.Order) orders;
    mapping(address => uint256) public takerValues;

    address public clearAnchor;
    uint256 public clearAnchorRatio = 10 ** 10;
    uint256 public clearAnchorRatioDecimals = 10;

    address public taker;
    address public maker;

    address public manager;

    uint256 public indexPriceID;

    uint256 public clearAnchorDecimals;
    uint256 public constant priceDecimals = 10;
    uint256 public constant amountDecimals = 10;
    uint256 public constant leverageDecimals = 10;

    uint256 public takerLeverageMin = 1;
    uint256 public takerLeverageMax = 100;
    uint256 public takerMarginMin = 10000;
    uint256 public takerMarginMax = 10 ** 30;
    uint256 public takerValueMin = 10000;
    uint256 public takerValueMax = 10 ** 40;

    uint256 public takerValueLimit = 10 ** 30;

    uint256 public makerLeverageRate = 5;

    //the rate is x/1000000
    uint256 public constant mmDecimal = 1000000;
    uint256 public mm = 5000;

    uint256 public coinMaxPrice = 1000000 * 10 ** 10;

    //the rate is x/10000
    uint256 public constant feeDecimal = 10000;
    uint256 public feeRate = 10;
    uint256 public feeInvitorPercent = 4000;
    uint256 public feeExchangePercent = 4000;
    uint256 public feeMakerPercent = 2000;

    mapping(address => uint256[]) public takerOrderlist;

    bool public openPaused = true;
    bool public closePaused = true;

    constructor(address _manager) public {
        manager = _manager;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "caller is not the controller");
        _;
    }

    modifier onlyRouter() {
        require(IManager(manager).checkRouter(msg.sender), "caller is not the router");
        _;
    }

    modifier whenNotOpenPaused() {
        require(!IManager(manager).paused() && !openPaused, "paused");
        _;
    }

    modifier whenNotClosePaused() {
        require(!IManager(manager).paused() && !closePaused, "paused");
        _;
    }

    function setPaused(bool _open, bool _close) external onlyController {
        openPaused = _open;
        closePaused = _close;
    }

    function initialize(uint256 _indexPrice, address _clearAnchor, uint256 _clearAnchorRatio, address _maker, uint8 _marketType) external {
        require(msg.sender == manager, "not manager");
        indexPriceID = _indexPrice;
        clearAnchor = _clearAnchor;
        clearAnchorRatio = _clearAnchorRatio;
        maker = _maker;
        taker = IManager(manager).taker();
        marketType = _marketType;
        clearAnchorDecimals = IERC20(clearAnchor).decimals();
    }

    function setClearAnchorRatio(uint256 _ratio) external onlyController {
        require(marketType == 2 && _ratio > 0, "error");
        clearAnchorRatio = _ratio;
    }

    function setTakerLeverage(uint256 min, uint256 max) external onlyController {
        require(min > 0 && min < max, "value not right");
        takerLeverageMin = min;
        takerLeverageMax = max;
    }

    function setTakerMargin(uint256 min, uint256 max) external onlyController {
        require(min > 0 && min < max, "value not right");
        takerMarginMin = min;
        takerMarginMax = max;
    }

    function setTakerValue(uint256 min, uint256 max) external onlyController {
        require(min > 0 && min < max, "value not right");
        takerValueMin = min;
        takerValueMax = max;
    }

    function setTakerValueLimit(uint256 limit) external onlyController {
        require(limit > 0, "limit not be zero");
        takerValueLimit = limit;
    }

    function setFee(
        uint256 _feeRate,
        uint256 _feeInvitorPercent,
        uint256 _feeExchangePercent,
        uint256 _feeMakerPercent
    ) external onlyController {
        require(_feeInvitorPercent.add(_feeMakerPercent).add(_feeExchangePercent) == feeDecimal, "percent all not one");
        require(_feeRate < feeDecimal, "feeRate more than one");
        feeRate = _feeRate;
        feeInvitorPercent = _feeInvitorPercent;
        feeExchangePercent = _feeExchangePercent;
        feeMakerPercent = _feeMakerPercent;
    }

    function setMM(uint256 _mm) external onlyController {
        require(_mm > 0 && _mm < mmDecimal, "mm is not right");
        mm = _mm;
    }

    function setCoinMaxPrice(uint256 max) external onlyController {
        require(max > 0 , "mm is not right");
        coinMaxPrice = max;
    }

    function setMakerLevarageRate(uint256 rate) external onlyController {
        require(rate > 0, "value is not right");
        makerLeverageRate = rate;
    }

    function open(
        address _taker,
        address inviter,
        uint256 minPrice,
        uint256 maxPrice,
        uint256 margin,
        uint256 leverage,
        int8 direction
    ) external nonReentrant onlyRouter whenNotOpenPaused returns (uint256 id) {
        require(minPrice <= maxPrice, "price error");
        require(direction == 1 || direction == - 1, "direction not allow");
        require(takerLeverageMin <= leverage && leverage <= takerLeverageMax, "leverage not allow");
        require(takerMarginMin <= margin && margin <= takerMarginMax, "margin not allow");
        require(takerValueMin <= margin.mul(leverage) && margin.mul(leverage) <= takerValueMax, "value not allow");

        uint256 fee = margin.mul(feeRate).mul(leverage).div(feeRate.mul(leverage).add(feeDecimal));
        uint256 imargin = margin.sub(fee);
        uint256 value = imargin.mul(leverage);

        require(value.add(takerValues[_taker]) < takerValueLimit, "taker total value too big");

        require(IUser(taker).balance(clearAnchor, _taker) >= margin, "balance not enough");
        bool success = IUser(taker).transfer(clearAnchor, _taker, margin);
        require(success, "transfer error");

        insertID++;
        id = insertID;
        Types.Order storage order = orders[id];
        order.id = id;
        order.inviter = inviter;
        order.taker = _taker;
        order.takerOpenTimestamp = block.timestamp;
        order.takerOpenDeadline = block.number.add(IManager(manager).cancelBlockElapse());
        order.takerOpenPriceMin = minPrice;
        order.takerOpenPriceMax = maxPrice;
        order.takerMargin = imargin;
        order.takerInitMargin = imargin;
        order.takerLeverage = leverage;
        order.takerTrueLeverage = leverage * (10 ** leverageDecimals);
        order.direction = direction;
        order.takerFee = fee;
        if (inviter != address(0)) {
            order.feeToInviter = fee.mul(feeInvitorPercent).div(feeDecimal);
        }
        order.feeToMaker = fee.mul(feeMakerPercent).div(feeDecimal);
        order.feeToExchange = fee.sub(order.feeToInviter).sub(order.feeToMaker);

        require(order.takerFee == (order.feeToInviter).add(order.feeToExchange).add(order.feeToMaker), "fee add error");
        require(margin == (order.takerMargin).add(order.takerFee), "margin add error");

        order.deadline = block.number.add(IManager(manager).openLongBlockElapse());
        order.status = Types.OrderStatus.Open;
        takerOrderlist[_taker].push(id);
        takerValues[_taker] = value.add(takerValues[_taker]);
    }

    function priceToOpen(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external nonReentrant onlyRouter {
        Types.Order storage order = orders[id];
        require(order.id > 0, "order not exist");
        require(order.status == Types.OrderStatus.Open, "order status not match");
        require(block.number < order.takerOpenDeadline, "deadline");
        require(price >= order.takerOpenPriceMin && price <= order.takerOpenPriceMax, "price not match");

        order.openPrice = price;
        order.openIndexPrice = indexPrice;
        order.openIndexPriceTimestamp = indexPriceTimestamp;

        uint256 margin = order.takerMargin;
        if (marketType == 2) {
            margin = margin.mul(10 ** clearAnchorRatioDecimals).div(clearAnchorRatio);
        }
        order.clearAnchorRatio = clearAnchorRatio;

        if (marketType == 0 || marketType == 2) {
            order.amount = (margin).mul(order.takerLeverage).mul(10 ** amountDecimals).mul(10 ** priceDecimals).div(price).div(10 ** clearAnchorDecimals);
        } else {
            order.amount = (margin).mul(order.takerLeverage).mul(price).mul(10 ** amountDecimals).div(10 ** priceDecimals).div(10 ** clearAnchorDecimals);
        }

        order.makerLeverage = order.takerLeverage.add(makerLeverageRate - 1).div(makerLeverageRate);
        order.makerMargin = (order.takerMargin).mul(order.takerLeverage).div(order.makerLeverage);

        bool success = IMaker(maker).open(order.makerMargin);
        require(success, "maker open fail");
        IMaker(maker).openUpdate(order.makerMargin, order.takerMargin, order.amount, margin.mul(order.takerLeverage), order.direction);

        if (order.direction > 0) {
            if (marketType == 0 || marketType == 2) {
                order.makerBrokePrice = price.add(price.div(order.makerLeverage));
                uint256 takerBrokePrice = price.sub(price.div(order.takerLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).sub(mm));
            } else {
                order.makerBrokePrice = coinMaxPrice;
                if (order.makerLeverage > 1) {
                    order.makerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals - uint256(10**leverageDecimals).div(order.makerLeverage));
                }
                uint256 takerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals + uint256(10**leverageDecimals).div(order.takerLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal + mm).div(mmDecimal);
            }
        } else {
            if (marketType == 0 || marketType == 2) {
                order.makerBrokePrice = price.sub(price.div(order.makerLeverage));
                uint256 takerBrokePrice = price.add(price.div(order.takerLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).add(mm));
            } else {
                order.makerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals + uint256(10**leverageDecimals).div(order.makerLeverage));
                uint256 takerBrokePrice = coinMaxPrice;
                if (order.takerLeverage > 1) {
                    takerBrokePrice = price.mul(10**leverageDecimals).div(10**leverageDecimals - uint256(10**leverageDecimals).div(order.takerLeverage));
                }
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal - mm).div(mmDecimal);
            }
        }

        order.status = Types.OrderStatus.Opened;
    }

    function depositMargin(address _taker, uint256 _id, uint256 _value) external nonReentrant onlyRouter {
        Types.Order storage order = orders[_id];
        require(order.id > 0, "order not exist");
        require(order.taker == _taker, 'caller is not taker');
        require(order.status == Types.OrderStatus.Opened, "order status not match");

        order.takerMargin = order.takerMargin.add(_value);
        require(order.makerMargin >= order.takerMargin, 'margin is error');
        IMaker(maker).takerDepositMarginUpdate(_value);

        require(IUser(taker).balance(clearAnchor, order.taker) >= _value, "balance not enough");
        bool success = IUser(taker).transfer(clearAnchor, order.taker, _value);
        require(success, "transfer error");

        order.takerTrueLeverage = (order.takerInitMargin).mul(order.takerLeverage).mul(10 ** leverageDecimals).div(order.takerMargin);

        if (order.direction > 0) {
            if (marketType == 0 || marketType == 2) {
                uint256 takerBrokePrice = order.openPrice.sub(order.openPrice.mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).sub(mm));
            } else {
                uint256 takerBrokePrice = order.openPrice.mul(10**leverageDecimals).div(10**leverageDecimals + uint256(10**leverageDecimals).mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal + mm).div(mmDecimal);
            }
        } else {
            if (marketType == 0 || marketType == 2) {
                uint256 takerBrokePrice = order.openPrice.add(order.openPrice.mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal).div(uint256(mmDecimal).add(mm));
            } else {
                uint256 takerBrokePrice = coinMaxPrice;
                if (order.takerTrueLeverage > 10**leverageDecimals) {
                    takerBrokePrice = order.openPrice.mul(10**leverageDecimals).div(10**leverageDecimals - uint256(10**leverageDecimals).mul(10 ** leverageDecimals).div(order.takerTrueLeverage));
                }
                order.takerBrokePrice = takerBrokePrice;
                order.takerLiquidationPrice = takerBrokePrice.mul(mmDecimal - mm).div(mmDecimal);
            }
        }

    }

    function close(address _taker, uint256 id, uint256 minPrice, uint256 maxPrice) external nonReentrant onlyRouter whenNotClosePaused {
        require(minPrice <= maxPrice, "price error");

        Types.Order storage order = orders[id];
        require(order.id > 0, "order not exist");
        require(order.taker == _taker, "not the taker");
        require(order.status == Types.OrderStatus.Opened, "order status not match");

        order.takerCloseTimestamp = block.timestamp;
        order.takerCloseDeadline = block.number.add(IManager(manager).cancelBlockElapse());
        order.takerClosePriceMin = minPrice;
        order.takerClosePriceMax = maxPrice;
        order.status = Types.OrderStatus.Close;
    }

    function priceToClose(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external nonReentrant onlyRouter {
        require(orders[id].id > 0, "order not exist");
        require(orders[id].status == Types.OrderStatus.Close, "order status not match");
        require(block.number < orders[id].takerCloseDeadline, "deadline");
        require(price >= orders[id].takerClosePriceMin && price <= orders[id].takerClosePriceMax, "price not match");

        orders[id].closeIndexPrice = indexPrice;
        orders[id].closeIndexPriceTimestamp = indexPriceTimestamp;
        _close(id, price);
    }

    function liquidity(uint256 id, uint256 price, uint256 indexPrice, uint256 indexPriceTimestamp) external nonReentrant onlyRouter {
        require(orders[id].id > 0, "order not exist");
        require(orders[id].status == Types.OrderStatus.Opened || orders[id].status == Types.OrderStatus.Close, "order status not match");

        if (block.number < orders[id].deadline) {
            if (orders[id].direction > 0) {
                require(price <= orders[id].takerLiquidationPrice || price >= orders[id].makerBrokePrice, "price not match");
            } else {
                require(price <= orders[id].makerBrokePrice || price >= orders[id].takerLiquidationPrice, "price not match");
            }
        }

        orders[id].closeIndexPrice = indexPrice;
        orders[id].closeIndexPriceTimestamp = indexPriceTimestamp;
        _close(id, price);
    }

    function _close(uint256 id, uint256 price) internal {
        bool isLiquidity;
        bool isBroke;
        if (orders[id].direction > 0) {
            if (price >= orders[id].makerBrokePrice) {
                isBroke = true;
            }
            if (price <= orders[id].takerLiquidationPrice) {
                isLiquidity = true;
            }
        } else {
            if (price <= orders[id].makerBrokePrice) {
                isBroke = true;
            }
            if (price >= orders[id].takerLiquidationPrice) {
                isLiquidity = true;
            }
        }

        int256 profit;
        if (isBroke) {
            profit = int256(orders[id].makerMargin);
            orders[id].status = Types.OrderStatus.Broke;
            orders[id].closePrice = orders[id].makerBrokePrice;
        } else {
            if (isLiquidity) {
                price = orders[id].takerLiquidationPrice;
            }

            if (marketType == 0 || marketType == 2) {
                profit = (int256(price).sub(int256(orders[id].openPrice))).mul(int256(10 ** clearAnchorDecimals)).mul(int256(orders[id].amount)).div(int256(10 ** (priceDecimals + amountDecimals)));
                if (marketType == 2) {
                    profit = profit.mul(int256(orders[id].clearAnchorRatio)).div(int256(10 ** clearAnchorRatioDecimals));
                }
            } else {
                uint256 a = (orders[id].amount).mul(10 ** (clearAnchorDecimals + priceDecimals)).div(orders[id].openPrice).div(10 ** amountDecimals);
                uint256 b = (orders[id].amount).mul(10 ** (priceDecimals + clearAnchorDecimals)).div(price).div(10 ** amountDecimals);
                profit = int256(a).sub(int256(b));
            }
            profit = profit.mul(orders[id].direction);
            if (block.number >= orders[id].deadline) {
                orders[id].status = Types.OrderStatus.Expired;
            } else {
                orders[id].status = Types.OrderStatus.Closed;
            }
            orders[id].closePrice = price;

            if (isLiquidity) {
                require(profit < 0, "profit error");
                require(- profit < int256(orders[id].takerMargin), "profit too big");
                orders[id].status = Types.OrderStatus.Liquidation;
                orders[id].riskFunding = orders[id].takerMargin.sub(uint256(- profit));
            }
        }

        orders[id].takerProfit = profit;
        orders[id].makerProfit = - profit;

        _settle(id);
    }

    function _settle(uint256 id) internal {
        TransferHelper.safeTransfer(clearAnchor, IManager(manager).feeOwner(), orders[id].feeToExchange);

        if (orders[id].feeToInviter > 0) {
            TransferHelper.safeTransfer(clearAnchor, orders[id].inviter, orders[id].feeToInviter);
        }

        if (orders[id].riskFunding > 0) {
            TransferHelper.safeTransfer(clearAnchor, IManager(manager).riskFundingOwner(), orders[id].riskFunding);
        }

        int256 takerBalance = int256(orders[id].takerMargin).add(orders[id].takerProfit).sub(int256(orders[id].riskFunding));
        require(takerBalance >= 0, "takerBalance error");
        if (takerBalance > 0) {
            TransferHelper.safeTransfer(clearAnchor, taker, uint256(takerBalance));
            IUser(taker).receiveToken(clearAnchor, orders[id].taker, uint256(takerBalance));
        }

        int256 makerBalance = int256(orders[id].makerMargin).add(orders[id].makerProfit).add(int256(orders[id].feeToMaker));
        require(makerBalance >= 0, "takerBalance error");
        if (makerBalance > 0) {
            TransferHelper.safeTransfer(clearAnchor, maker, uint256(makerBalance));
        }
        uint256 margin = orders[id].takerInitMargin;
        if (marketType == 2) {
            margin = margin.mul(10 ** clearAnchorRatioDecimals).div(orders[id].clearAnchorRatio);
        }
        IMaker(maker).closeUpdate(orders[id].makerMargin, orders[id].takerMargin, orders[id].amount, margin.mul(orders[id].takerLeverage), orders[id].makerProfit, orders[id].feeToMaker, orders[id].direction);

        uint256 income = (orders[id].takerMargin).add(orders[id].takerFee).add(orders[id].makerMargin);
        uint256 payout = (orders[id].feeToInviter).add(orders[id].feeToExchange).add(orders[id].riskFunding).add(uint256(takerBalance)).add(uint256(makerBalance));
        require(income == payout, "settle error");

        uint256 value = orders[id].takerInitMargin.mul(orders[id].takerLeverage);
        takerValues[orders[id].taker] = takerValues[orders[id].taker].sub(value);
    }

    function openCancel(address _taker, uint256 id) external nonReentrant onlyRouter {
        require(orders[id].taker == _taker, "not taker");
        require(orders[id].status == Types.OrderStatus.Open, "not open");
        require(orders[id].takerOpenDeadline < block.number, "deadline");
        _cancel(id);
    }

    function closeCancel(address _taker, uint256 id) external nonReentrant onlyRouter {
        require(orders[id].taker == _taker, "not taker");
        require(orders[id].status == Types.OrderStatus.Close, "not close");
        require(orders[id].takerCloseDeadline < block.number, "deadline");

        orders[id].status = Types.OrderStatus.Opened;
    }

    function priceToOpenCancel(uint256 id) external nonReentrant onlyRouter {
        require(orders[id].status == Types.OrderStatus.Open, "not open");
        _cancel(id);
    }

    function priceToCloseCancel(uint256 id) external nonReentrant onlyRouter {
        require(orders[id].status == Types.OrderStatus.Close, "not close");
        orders[id].status = Types.OrderStatus.Opened;
    }

    function _cancel(uint256 id) internal {
        orders[id].status = Types.OrderStatus.Canceled;
        uint256 value = orders[id].takerInitMargin.mul(orders[id].takerLeverage);
        takerValues[orders[id].taker] = takerValues[orders[id].taker].sub(value);
        uint256 balance = orders[id].takerMargin.add(orders[id].takerFee);
        TransferHelper.safeTransfer(clearAnchor, taker, balance);
        IUser(taker).receiveToken(clearAnchor, orders[id].taker, balance);
    }

    function getTakerOrderlist(address _taker) external view returns (uint256[] memory) {
        return takerOrderlist[_taker];
    }

    function getByID(uint256 id) external view returns (bytes memory) {
        bytes memory _preBytes = abi.encode(
            orders[id].inviter,
            orders[id].taker,
            orders[id].takerOpenDeadline,
            orders[id].takerOpenPriceMin,
            orders[id].takerOpenPriceMax,
            orders[id].takerMargin,
            orders[id].takerLeverage,
            orders[id].direction,
            orders[id].takerFee
        );
        bytes memory _postBytes = abi.encode(
            orders[id].feeToInviter,
            orders[id].feeToExchange,
            orders[id].feeToMaker,
            orders[id].openPrice,
            orders[id].openIndexPrice,
            orders[id].openIndexPriceTimestamp,
            orders[id].amount,
            orders[id].makerMargin,
            orders[id].makerLeverage,
            orders[id].takerLiquidationPrice
        );

        bytes memory tempBytes = Bytes.contact(_preBytes, _postBytes);

        _postBytes = abi.encode(
            orders[id].takerBrokePrice,
            orders[id].makerBrokePrice,
            orders[id].takerCloseDeadline,
            orders[id].takerClosePriceMin,
            orders[id].takerClosePriceMax,
            orders[id].closePrice,
            orders[id].closeIndexPrice,
            orders[id].closeIndexPriceTimestamp,
            orders[id].takerProfit,
            orders[id].makerProfit
        );

        tempBytes = Bytes.contact(tempBytes, _postBytes);

        _postBytes = abi.encode(
            orders[id].riskFunding,
            orders[id].deadline,
            orders[id].status,
            orders[id].takerOpenTimestamp,
            orders[id].takerCloseTimestamp,
            orders[id].clearAnchorRatio,
            orders[id].takerInitMargin,
            orders[id].takerTrueLeverage
        );

        tempBytes = Bytes.contact(tempBytes, _postBytes);

        return tempBytes;
    }

}
