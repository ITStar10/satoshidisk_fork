import { ethers } from "hardhat";

async function main() {
  const BNBDisk = await ethers.getContractFactory('BNBDisk');
  console.log('Deploying BNBDisk...');
  const bnbDisk = await BNBDisk.deploy()

  await bnbDisk.deployed();
  console.log('BNBDisk deployed to:', bnbDisk.address);
  // HardHat : 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  // Ganache : 0x57c1593B240E1e2a43c7BF3e8f9d3Cc79C2d4C89
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// BSC TestNet
// 0xE40d2fE8C84b85AD4640FC8D3a2F8011B989756d

// BSC MainNet
// 0x5fE07c8a5595432B3F89D643b485a24d1aaCF30A