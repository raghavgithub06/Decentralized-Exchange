require("@nomiclabs/hardhat-ethers");

const ALCHEMY_API_KEY = "PQdUX5K_wmS4LBV3TJBIg0e6VzSoz0GQ";
const PRIVATE_KEY = "1b0e72aa33c9b205609c8a7910ce9c7d6a580ef9d81599b83388d6181c2f2768";

module.exports = {
  solidity: "0.8.0",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/PQdUX5K_wmS4LBV3TJBIg0e6VzSoz0GQ`,
      accounts: [`0x1b0e72aa33c9b205609c8a7910ce9c7d6a580ef9d81599b83388d6181c2f2768`]
    }
  },
  paths: {
    sources: "./contracts",
  },
  mocha: {
    timeout: 20000,
  },
};