module.exports = {
  networks: {
    mainnet: {
      privateKey: "",
      userFeePercentage: 100,
      feeLimit: 1e9,
      fullHost: 'https://api.trongrid.io',
      network_id: '1'
    },
    shasta: {
      privateKey: "",
      userFeePercentage: 50,
      feeLimit: 1e9,
      fullHost: 'https://api.shasta.trongrid.io',
      network_id: '2'
    },
    compilers: {
      solc: {
        version: '0.5.15'
      }
    }
  }
}