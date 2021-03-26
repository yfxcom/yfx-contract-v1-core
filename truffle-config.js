/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * truffleframework.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */


var HDWalletProvider = require("truffle-hdwallet-provider");
var privateKey = "";

module.exports = {
    networks: {
        bsc_mainnet: {
            provider: () => new HDWalletProvider(privateKey, 'https://bsc-dataseed1.binance.org'),
            network_id: 56,
            confirmations: 10,
            timeoutBlocks: 200,
            skipDryRun: true
        },
        bsc_testnet: {
            provider: () => new HDWalletProvider(privateKey, `https://data-seed-prebsc-2-s3.binance.org:8545/`),
            network_id: 97,
            confirmations: 1,
            timeoutBlocks: 200,
            skipDryRun: true,
            gas: 20000000,
            gasPrice: 150000000000
        },
    },
    compilers: {
        solc: {
            version: "0.5.15",
            settings: {
                optimizer: {
                    enabled: true,
                    runs: 200
                },
            }
        },
    },
};
