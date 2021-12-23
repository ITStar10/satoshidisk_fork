// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";


async function main() {

  const [ deployer ] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString);
  
  const SatoToken = await ethers.getContractFactory("SatoToken");
  const satoToken = await SatoToken.deploy();

  await satoToken.deployed();

  console.log("Token deployed to:", satoToken.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


// BSC TestNet deployed:
// 0x9835Da181CB9F4dB2364B33f6B46454A3de4ac66

// BSC testnet updated:
// 0xb0E9ceD3Ee656fbb48778982D784A3380B0875d5


// BSC Mainnet
// 0x14936f58C88151f1c4f989378b72c3296A0a4d78