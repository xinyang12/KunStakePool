usePlugin("@nomiclabs/buidler-waffle");
usePlugin("@nomiclabs/buidler-web3");
usePlugin("@nomiclabs/buidler-etherscan");
usePlugin('@openzeppelin/buidler-upgrades');

require('dotenv').config()

module.exports = {
  solc: {
    version: "0.6.4",
    optimize: true
  },
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${INFURA_ID}`,
      accounts: [`0x${PRIVATE_KEY}`]
    },
    buidlerevm: {
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_KEY
  }
};