import { ethers, upgrades } from "hardhat";

async function main() {
  const BNBDisk = await ethers.getContractFactory('BNBDiskUpgradeable');
  console.log('Deploying BNBDisk...');
  const bnbDisk = await upgrades.deployProxy(BNBDisk,[], { initializer: 'initialize'})
  // const bnbDisk = await upgrades.deployProxy(BNBDisk)
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
