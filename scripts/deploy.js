const { ethers } = require("hardhat");

async function main() {
  const DecentralizedExchange = await ethers.getContractFactory("DecentralizedExchange");
  const MockERC20 = await ethers.getContractFactory("MockERC20");

  console.log("Deploying MockERC20...");
  const mockToken = await MockERC20.deploy("Mock Token", "MTK");
  await mockToken.deployed();
  console.log("MockERC20 deployed to:", mockToken.address);

  console.log("Deploying DecentralizedExchange...");
  const exchange = await DecentralizedExchange.deploy(mockToken.address);
  await exchange.deployed();
  console.log("DecentralizedExchange deployed to:", exchange.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });