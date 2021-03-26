pragma solidity >=0.5.15  <=0.5.17;

interface IMaker {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);

    function sharePrice() external view returns (uint);

    function setMinAddLiquidityAmount(uint _minAmount) external returns (bool);

    function setMinRemoveLiquidity(uint _minLiquidity) external returns (bool);

    function setOpenRate(uint _openRate) external returns (bool);

    function setRemoveLiquidityRate(uint _rate) external returns (bool);

    function canOpen(uint _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint[] memory);

    function getOrder(uint _no) external view returns (bytes memory _order);

    function openUpdate(uint _makerMargin, uint _takerMargin, uint _amount, uint _total, int8 _takerDirection) external returns (bool);

    function closeUpdate(
        uint _makerMargin,
        uint _takerMargin,
        uint _amount,
        uint _total,
        int makerProfit,
        uint makerFee,
        int8 _takerDirection
    ) external returns (bool);

    function open(uint _value) external returns (bool);

    function takerDepositMarginUpdate(uint _margin) external returns (bool);

    function addLiquidity(address sender, uint amount) external returns (uint _id, address _makerAddress, uint _amount, uint _cancelBlockElapse);

    function cancelAddLiquidity(address sender, uint id) external returns (uint _amount);

    function priceToAddLiquidity(uint256 id, uint256 price, uint256 priceTimestamp) external returns (uint liquidity);

    function removeLiquidity(address sender, uint liquidity) external returns (uint _id, address _makerAddress, uint _liquidity, uint _cancelBlockElapse);

    function priceToRemoveLiquidity(uint id, uint price, uint priceTimestamp) external returns (uint amount);

    function cancelRemoveLiquidity(address sender, uint id) external returns (bool);

    function getLpBalanceOf(address _maker) external view returns (uint _balance, uint _totalSupply);

    function systemCancelAddLiquidity(uint id) external;

    function systemCancelRemoveLiquidity(uint id) external;

    function canRemoveLiquidity(uint _price, uint _liquidity) external view returns (bool);

    function canAddLiquidity(uint _price) external view returns (bool);
}
