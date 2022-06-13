const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Temperature", function () {
  it("Should return the new temperature once it's changed", async function () {
    const Temperature = await ethers.getContractFactory("Temperature");
    const temperature = await Temperature.deploy();
    await temperature.deployed();

    // apply for provider
    const owners = await ethers.getSigners();
    const owner1 = owners[1];
    const owner2 = owners[2];
    const owner3 = owners[3];
    const owner4 = owners[4];
    const owner5 = owners[5];
    const owner6 = owners[6];

    const changeTemperature = -3619;
    await expect(temperature.setTemperatureByNode(changeTemperature)).to.be.revertedWith("Provider not existed");

    let tx = await (await temperature.applyProvider({
      value: ethers.utils.parseEther("100").toString()
    })).wait();
    console.log(tx.events[0].args);
    await temperature.connect(owner1).applyProvider({ value: ethers.utils.parseEther("100").toString() });
    await temperature.connect(owner2).applyProvider({ value: ethers.utils.parseEther("100").toString() });
    await temperature.connect(owner3).applyProvider({ value: ethers.utils.parseEther("100").toString() });
    await temperature.connect(owner4).applyProvider({ value: ethers.utils.parseEther("100").toString() });
    await temperature.connect(owner5).applyProvider({ value: ethers.utils.parseEther("100").toString() });
    await temperature.connect(owner6).applyProvider({ value: ethers.utils.parseEther("100").toString() });
    console.log("lastBlockNumber ", await temperature.lastBlockNumber());

    await expect(temperature.connect(owner6).recallProvider()).to.be.revertedWith("Wait more block");

    const changeTemperature1 = 3619;
    const changeTemperature2 = 3659;
    const changeTemperature3 = 3679;
    const changeTemperature4 = 3724;
    const changeTemperature5 = 3689;
    const changeTemperature6 = 3680;
    await temperature.setTemperatureByNode(changeTemperature);
    await temperature.connect(owner1).setTemperatureByNode(changeTemperature1);
    await temperature.connect(owner2).setTemperatureByNode(changeTemperature2);
    await temperature.connect(owner3).setTemperatureByNode(changeTemperature3);
    await temperature.connect(owner4).setTemperatureByNode(changeTemperature4);
    await temperature.connect(owner5).setTemperatureByNode(changeTemperature5);
    await temperature.connect(owner6).setTemperatureByNode(changeTemperature6);
    await temperature.connect(owner1).setTemperatureByNode(changeTemperature1);
    console.log("temperature ", await temperature.getTemperature());
    
  });
});
