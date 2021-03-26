pragma solidity >=0.5.15  <=0.5.17;

interface IWrappedCoin {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}
