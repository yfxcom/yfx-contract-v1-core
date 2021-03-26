pragma solidity >=0.5.15  <=0.5.17;

library Types {
    enum OrderStatus {
        Open,
        Opened,
        Close,
        Closed,
        Liquidation,
        Broke,
        Expired,
        Canceled
    }

    enum PoolAction {
        Deposit,
        Withdraw
    }
    enum PoolActionStatus {
        Submit,
        Success,
        Fail,
        Cancel
    }

    struct Order {
        uint256 id;

        uint256 takerLeverage;
        //the rate is x/10000000000
        uint256 takerTrueLeverage;
        int8 direction;
        address inviter;
        address taker;
        uint256 takerOpenTimestamp;
        uint256 takerOpenDeadline;
        uint256 takerOpenPriceMin;
        uint256 takerOpenPriceMax;
        uint256 takerMargin;
        uint256 takerInitMargin;
        uint256 takerFee;
        uint256 feeToInviter;
        uint256 feeToExchange;
        uint256 feeToMaker;

        uint256 openPrice;
        uint256 openIndexPrice;
        uint256 openIndexPriceTimestamp;
        uint256 amount;
        uint256 makerMargin;
        uint256 makerLeverage;
        uint256 takerLiquidationPrice;
        uint256 takerBrokePrice;
        uint256 makerBrokePrice;
        uint256 clearAnchorRatio;

        uint256 takerCloseTimestamp;
        uint256 takerCloseDeadline;
        uint256 takerClosePriceMin;
        uint256 takerClosePriceMax;

        uint256 closePrice;
        uint256 closeIndexPrice;
        uint256 closeIndexPriceTimestamp;
        uint256 riskFunding;
        int256 takerProfit;
        int256 makerProfit;

        uint256 deadline;
        OrderStatus status;

    }

    struct MakerOrder {
        uint256 id;
        address maker;
        uint256 submitBlockHeight;
        uint256 submitBlockTimestamp;
        uint256 price;
        uint256 priceTimestamp;
        uint256 amount;
        uint256 liquidity;
        uint256 feeToPool;
        uint256 cancelBlockHeight;
        uint256 sharePrice;
        int poolTotal;
        int profit;
        PoolAction action;
        PoolActionStatus status;
    }
}
