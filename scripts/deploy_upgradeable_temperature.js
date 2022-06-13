// npx hardhat run --network localhost scripts/deploy_upgradeable_temperature.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const Temperature = await ethers.getContractFactory("Temperature");
  const temperature = await upgrades.deployProxy(Temperature);
  await temperature.deployed();
  console.log("Temperature deployed to:", temperature.address);
}

main();
