// npx hardhat run --network localhost scripts/upgrade_temperature.js
const { ethers, upgrades } = require("hardhat");

async function main() {
  const V1Address = "";
  const TemperatureV2 = await ethers.getContractFactory("TemperatureV2");
  const temperature = await upgrades.upgradeProxy(V1Address, TemperatureV2);
  console.log("Temperature upgraded");
}

main();
