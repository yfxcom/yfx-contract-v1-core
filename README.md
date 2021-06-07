# YFX Perpetual Contracts V1 Protocol

This repository contains the core smart contracts for the YFX Perpetual Contract V1 Protocol.

> YFX is a trading platform provide up to 100x leverage to trade on BTC, ETH and other crypto assets support by ETH, Tron, BSC, Heco, OKEx Chain, Polkadot. By invent QIC-AMM, YFX provide high liquidity and low slippage.

## WebSites
|  Chain |  Domain  |
| ------------ | ------------ |
|  Main | [https://www.yfx.com/](https://www.yfx.com/?utm_source=github "https://www.yfx.com/")  |
|Heco| [https://ht.yfx.com/](https://ht.yfx.com/?utm_source=github "https://ht.yfx.com/")|
|BSC| [https://bsc.yfx.com/](https://bsc.yfx.com/?utm_source=github "https://bsc.yfx.com/")|
|ETH Xdai| [https://xdai.yfx.com/](https://xdai.yfx.com/?utm_source=github "https://xdai.yfx.com/")|
|Tron| [https://trx.yfx.com/](https://trx.yfx.com/?utm_source=github "https://trx.yfx.com/")|


## About the Contracts Code
| File  |  introduction   |  Functions |
| ------------ | ------------ | ------------ |
| Router.sol  |  Router  | takerOpen, Open, takerClose, Close, Cancel, AddLiquidity, RemoveLiquidity, canOpen...  |
| User.sol  | Deposit & withdraw  | Deposit & withdraw Function  |
|Manager.sol| Address Manager |checkMaker,checkMarket, checkRouter, checkSigner, createPair, changeOwner...|
|Maker.sol| Market Maker Pool|initialize, getOrder, open, openUpdate, closeUpdate,addLiquidity, cancelAddLiquidity, priceToAddLiquidity, removeLiquidity, systemCancelAddLiquidity, makerProfit... |
|Market.sol| Calculate the orders| open, close, closeCancel, priceToCloseCancel, priceToOpen...|


## QuickStart

truffle compile

truffle migrate --network bsc_mainnet


## [ETH Layer2 xDai](https://github.com/yfxcom/yfx-contract-v1-core/tree/xdai "ETH Layer2 xDai")
|  Type |  Market  | Contract Address  |
| ------------ | ------------ | ------------ |
|Router|---| [0x390Cb60328d8B7f1e6052AA8C053718e285a8f49](https://blockscout.com/xdai/mainnet/address/0x390Cb60328d8B7f1e6052AA8C053718e285a8f49/transactions "0x390Cb60328d8B7f1e6052AA8C053718e285a8f49") |
|User| --- | [0x4221aE23a51c915F0461ef2740664451F64b6A23](https://blockscout.com/xdai/mainnet/address/0x4221aE23a51c915F0461ef2740664451F64b6A23/transactions "0x4221aE23a51c915F0461ef2740664451F64b6A23") |
|Market| BTC_USDT(USDT Settled)|[0x2f8c1d90c800e111e201d086d4b2c494f03bb34e](https://blockscout.com/xdai/mainnet/address/0x2f8c1d90c800e111e201d086d4b2c494f03bb34e/transactions "0x2f8c1d90c800e111e201d086d4b2c494f03bb34e")|
|Market Pool| BTC_USD(USDC Settled)|[0xdb33944eb8802f9a29cb58800e424c1120a26ef1](https://blockscout.com/xdai/mainnet/address/0xdb33944eb8802f9a29cb58800e424c1120a26ef1/transactions "0xdb33944eb8802f9a29cb58800e424c1120a26ef1")|
|Market| BTC_USD(USDC Settled)|[0x256e4fad656f8c92296312a179c3e93a32fc26d7](https://blockscout.com/xdai/mainnet/address/0x256e4fad656f8c92296312a179c3e93a32fc26d7/transactions "0x256e4fad656f8c92296312a179c3e93a32fc26d7")|
|Market Pool| BTC_USD(USDC Settled)|[0x6ef0b675199d53654bdfcad450c7c085e9a4f9dc](https://blockscout.com/xdai/mainnet/address/0x6ef0b675199d53654bdfcad450c7c085e9a4f9dc/transactions "0x6ef0b675199d53654bdfcad450c7c085e9a4f9dc")|


## [Heco(Huobi Echo Chain)](https://github.com/yfxcom/yfx-contract-v1-core/tree/heco "Heco(Huobi Echo Chain)")
|  Type |  Market  | Contract Address  |
| ------------ | ------------ | ------------ |
| Router  |  --  |  [0x68Ef8c3e8a95f0F54c16A7502cBF0F9E16dbff81](https://hecoinfo.com/address/0x68Ef8c3e8a95f0F54c16A7502cBF0F9E16dbff81 "0x68Ef8c3e8a95f0F54c16A7502cBF0F9E16dbff81") |
| User  |  --  | [0xb6e6f6ad2b73464c8a83c8164933dcb91a039127](https://hecoinfo.com/address/0xb6e6f6ad2b73464c8a83c8164933dcb91a039127 "0xb6e6f6ad2b73464c8a83c8164933dcb91a039127")  |
| Market| BTC_USDT(USDT Settled)| [0xa1d915871ba93fe3ea1363bbdcf0a5ded3edc404](https://hecoinfo.com/address/0xa1d915871ba93fe3ea1363bbdcf0a5ded3edc404 "0xa1d915871ba93fe3ea1363bbdcf0a5ded3edc404")|
| Market Pool| BTC_USDT(USDT Settled) |[0x7e57b96650ad96b89dc32e16f5c05785b922bddd](https://hecoinfo.com/address/0x7e57b96650ad96b89dc32e16f5c05785b922bddd "0x7e57b96650ad96b89dc32e16f5c05785b922bddd")|
|Market| ETH_USDT(USDT Settled)|[0xdf356d8125c01e7a181dc24a25bc0aeb7d41affb](https://hecoinfo.com/address/0xdf356d8125c01e7a181dc24a25bc0aeb7d41affb "0xdf356d8125c01e7a181dc24a25bc0aeb7d41affb")|
|Market Pool| ETH_USDT(USDT Settled)|[0x891edddcc55930bb9372851b9a6a47b74a867fe9](https://hecoinfo.com/address/0x891edddcc55930bb9372851b9a6a47b74a867fe9 "0x891edddcc55930bb9372851b9a6a47b74a867fe9")|
|Market| BTC_USD(BTC Settled)|[0x33209747c98fc497d37cd2bddc0fb97ed302f149](https://hecoinfo.com/address/0x33209747c98fc497d37cd2bddc0fb97ed302f149 "0x33209747c98fc497d37cd2bddc0fb97ed302f149")|
|Market Pool| BTC_USD(BTC Settled)|[0x7c7e9f72e03e5db000e5bc0314733be117e0d369](https://hecoinfo.com/address/0x7c7e9f72e03e5db000e5bc0314733be117e0d369 "0x7c7e9f72e03e5db000e5bc0314733be117e0d369")|
|Market| ETH_USD(ETH Settled)|[0x0d047620466ceac40b506f7da8aa13baaa9d1adc](https://hecoinfo.com/address/0x0d047620466ceac40b506f7da8aa13baaa9d1adc "0x0d047620466ceac40b506f7da8aa13baaa9d1adc")|
|Market Pool| ETH_USD(ETH Settled)|[0x49d1408576bab0006952c2554759980a406352f2](https://hecoinfo.com/address/0x49d1408576bab0006952c2554759980a406352f2 "0x49d1408576bab0006952c2554759980a406352f2")|
|Market| BTC_USDT(HT Settled)|[0xa1b1582e7e695c97cdcfaed45b7e925b547c2d1a](https://hecoinfo.com/address/0xa1b1582e7e695c97cdcfaed45b7e925b547c2d1a "0xa1b1582e7e695c97cdcfaed45b7e925b547c2d1a")|
|Market Pool|BTC_USDT(HT Settled)| [0x6974eec45a4618f8e40d8a96debaa7a441bae3f0](https://hecoinfo.com/address/0x6974eec45a4618f8e40d8a96debaa7a441bae3f0 "0x6974eec45a4618f8e40d8a96debaa7a441bae3f0")|
|Market| BTC_USDT(HPT Settled)|[0x44ce1073301189c6e92a6ad787f6779102f6657f](https://hecoinfo.com/address/0x44ce1073301189c6e92a6ad787f6779102f6657f "0x44ce1073301189c6e92a6ad787f6779102f6657f")|
|Market Pool| BTC_USDT(HPT Settled)|[0x1ba75637253408ea22cdfefcd7ee1fb6236cdfb2](https://hecoinfo.com/address/0x1ba75637253408ea22cdfefcd7ee1fb6236cdfb2 "0x1ba75637253408ea22cdfefcd7ee1fb6236cdfb2")|
|Market| BTC_USDT(FILDA Settled)| [0x5c6aa4bae335da179ab66a2fb2f28101ff14e1e6](https://hecoinfo.com/address/0x5c6aa4bae335da179ab66a2fb2f28101ff14e1e6 "0x5c6aa4bae335da179ab66a2fb2f28101ff14e1e6")|
|Market Pool|BTC_USDT(FILDA Settled)|[0xbc6a32b99bc3ce29d3e907b75d3fe1b220d2a701](https://hecoinfo.com/address/0xbc6a32b99bc3ce29d3e907b75d3fe1b220d2a701 "0xbc6a32b99bc3ce29d3e907b75d3fe1b220d2a701")|
|Market| BTC_USDT(YFX Settled)|[0x0b5102794af564bf51d8a82db3f86d56308f0d1a](https://hecoinfo.com/address/0x0b5102794af564bf51d8a82db3f86d56308f0d1a "0x0b5102794af564bf51d8a82db3f86d56308f0d1a")|
|Market Pool|BTC_USDT(YFX Settled)|[0xc0b162ceb1c877be2ae8457bd88d07c550a9f0d5](https://hecoinfo.com/address/0xc0b162ceb1c877be2ae8457bd88d07c550a9f0d5 "0xc0b162ceb1c877be2ae8457bd88d07c550a9f0d5")|



## [BSC( Binance Smart Chain)](https://github.com/yfxcom/yfx-contract-v1-core/tree/bsc "BSC( Binance Smart Chain)")
|  Type |  Market  | Contract Address  |
| ------------ | ------------ | ------------ |
|Router| ---|[0x7Fc16a4b5098b25283769719aa2B0d0691E585f4](https://bscscan.com/address/0x7Fc16a4b5098b25283769719aa2B0d0691E585f4 "0x7Fc16a4b5098b25283769719aa2B0d0691E585f4")|
|User| --- |[0x1756b71164ca60bb98012fdb6036ee0ebd7a11f9](https://bscscan.com/address/0x1756b71164ca60bb98012fdb6036ee0ebd7a11f9 "0x1756b71164ca60bb98012fdb6036ee0ebd7a11f9")|
|Market| BTC_USDT(USDT Settled)|[0xed7da22f8fc565be473f1264f91577f1dc60cfce](https://bscscan.com/address/0xed7da22f8fc565be473f1264f91577f1dc60cfce "0xed7da22f8fc565be473f1264f91577f1dc60cfce")|
|Market Pool| BTC_USDT(USDT Settled)|[0x46a206ab96de17bb7e1c33db265239dd29e4f2f4](https://bscscan.com/address/0x46a206ab96de17bb7e1c33db265239dd29e4f2f4 "0x46a206ab96de17bb7e1c33db265239dd29e4f2f4")|
|Market|ETH_USDT(USDT Settled)|[0xe9f5c4730cb0c00a355f51b313e2e19b8555ca80](https://bscscan.com/address/0xe9f5c4730cb0c00a355f51b313e2e19b8555ca80 "0xe9f5c4730cb0c00a355f51b313e2e19b8555ca80")|
|Market Pool|ETH_USDT(USDT Settled)|[0x355859452d53f9bc23da3330f5786d0f189fc942](https://bscscan.com/address/0x355859452d53f9bc23da3330f5786d0f189fc942 "0x355859452d53f9bc23da3330f5786d0f189fc942")|
|Market|BTC_USD(BTC Settled)|[0x7c3a645810e4706db18d40d058476527dc392445](https://bscscan.com/address/0x7c3a645810e4706db18d40d058476527dc392445 "0x7c3a645810e4706db18d40d058476527dc392445")|
|Market Pool| BTC_USD(BTC Settled)|[0xbfcb78caf7b0f26528ca90cdbdeb0399ac09a7f9](https://bscscan.com/address/0xbfcb78caf7b0f26528ca90cdbdeb0399ac09a7f9 "0xbfcb78caf7b0f26528ca90cdbdeb0399ac09a7f9")|
|Market|ETH_USD(ETH Settled)|[0xa312957a2f88eb41e4679c16cedb4d3e0346e61f](https://bscscan.com/address/0xa312957a2f88eb41e4679c16cedb4d3e0346e61f "0xa312957a2f88eb41e4679c16cedb4d3e0346e61f")|
|Market Pool| ETH_USD(ETH Settled)|[0x8a4256e0c147d57986f3cc33b611c6a7128e1882](https://bscscan.com/address/0x8a4256e0c147d57986f3cc33b611c6a7128e1882 "0x8a4256e0c147d57986f3cc33b611c6a7128e1882")|
|Market|BTC_USDT(BNB Settled)|[0x8068e01ce5822d2cb2a14d555b4142362678dc1e](https://bscscan.com/address/0x8068e01ce5822d2cb2a14d555b4142362678dc1e "0x8068e01ce5822d2cb2a14d555b4142362678dc1e")|
|Market Pool|BTC_USDT(BNB Settled)|[0xe357e7d1e67c928b09c7b8494a78b068d1f66d9d](https://bscscan.com/address/0xe357e7d1e67c928b09c7b8494a78b068d1f66d9d "0xe357e7d1e67c928b09c7b8494a78b068d1f66d9d")|

## [Tron](https://github.com/yfxcom/yfx-contract-v1-core/tree/tron "Tron")
|  Type |  Market  | Contract Address  |
| ------------ | ------------ | ------------ |
|Router| ---|[TReePVFNh2nkhED2K4eNiewU6QTHTa72Qr](https://tronscan.io/#/contract/TReePVFNh2nkhED2K4eNiewU6QTHTa72Qr "TReePVFNh2nkhED2K4eNiewU6QTHTa72Qr")|
|User| --- |[TTTz9vVaFLbQQLxxVnYv7L5bbNhcwHgMjw](https://tronscan.io/#/contract/TTTz9vVaFLbQQLxxVnYv7L5bbNhcwHgMjw "TTTz9vVaFLbQQLxxVnYv7L5bbNhcwHgMjw")|
|Market|BTC_USDT(USDT Settled)|[TFBMDYhfTnTuvyNvGdNzBhAWR8AChqp4uH](https://tronscan.io/#/contract/TFBMDYhfTnTuvyNvGdNzBhAWR8AChqp4uH "TFBMDYhfTnTuvyNvGdNzBhAWR8AChqp4uH")|
|Market Pool| ETH_USDT(USDT Settled)|[TXNhLtTyfRAfUr6D25LgbnPcdvx7dgigYt](https://tronscan.io/#/contract/TXNhLtTyfRAfUr6D25LgbnPcdvx7dgigYt "TXNhLtTyfRAfUr6D25LgbnPcdvx7dgigYt")|
|Market| ETH_USDT(USDT Settled)|[TQkSSAH2FPTNUHkvJsdoJDLtpTgYPU6SEZ](https://tronscan.io/#/contract/TQkSSAH2FPTNUHkvJsdoJDLtpTgYPU6SEZ "TQkSSAH2FPTNUHkvJsdoJDLtpTgYPU6SEZ")|
|Market Pool|ETH_USDT(USDT Settled)|[TWis8MnxZMSZiYwmMqLvBoaLMftk3FgtnT](https://tronscan.io/#/contract/TWis8MnxZMSZiYwmMqLvBoaLMftk3FgtnT "TWis8MnxZMSZiYwmMqLvBoaLMftk3FgtnT")|
|Market|TRX_USDT(TRX Settled)|[TLd4KS5fMnxG343bEbjTrgLYVr6y4jX7x7](https://tronscan.io/#/contract/TLd4KS5fMnxG343bEbjTrgLYVr6y4jX7x7 "TLd4KS5fMnxG343bEbjTrgLYVr6y4jX7x7")|
|Market Pool|TRX_USDT(TRX Settled)|[TLd4KS5fMnxG343bEbjTrgLYVr6y4jX7x7](https://tronscan.io/#/contract/TLd4KS5fMnxG343bEbjTrgLYVr6y4jX7x7 "TLd4KS5fMnxG343bEbjTrgLYVr6y4jX7x7")|






