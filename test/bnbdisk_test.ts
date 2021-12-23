import chai from "chai"
import chaiAsPromised from "chai-as-promised"
import { solidity } from 'ethereum-waffle'
import { expect } from "chai"
import { ethers } from "hardhat"

import { BNBDisk } from "../typechain";
import { Address } from "cluster"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import { BigNumber } from "@ethersproject/bignumber"
chai.use(solidity)
chai.use(chaiAsPromised)

import hre from "hardhat";

// async function main() {
//   const networkName = hre.network.name;
//   const chainId = hre.network.config.chainId;
//   console.log("HRE Name ", networkName, " - ", chainId);

describe ("BNBDisk", function() {
  let bnbDisk : BNBDisk;
  // let owner : SignerWithAddress, accnt1 : SignerWithAddress, accnt2 : SignerWithAddress;

  let accountList : SignerWithAddress[];
  let owner : SignerWithAddress;

  const networkName = hre.network.name;
  const chainId = hre.network.config.chainId;

  console.log("HRE : ", networkName, " - ", chainId);

  this.beforeAll(async function () {
    // accountList = await ethers.getSigners();
    accountList = await hre.ethers.getSigners();
    owner = accountList[0];
    
    const BNBDisk = await ethers.getContractFactory("BNBDisk");
    bnbDisk = await BNBDisk.deploy();

    // console.log("===========Account List==========");
    // accountList.forEach(async (item, index) => {
    //   console.log(index, " - ", item.address)

    //   await bnbDisk.mintNFT(
    //     item.address,
    //     "TestURI- " + index,
    //     100, // Price
    //     // (index + 1) * 100, // Count
    //     50, //Count
    //   )
    // });
  });

  it ("BNBDisk mint nft items", async function() {
    for (let i = 0; i < 5; i++) {
      await bnbDisk.mintNFT(
        accountList[i].address,
        "TestURI --- " + i,
        100, // price
        50 // Count
      )
    }

    expect(await bnbDisk.getNumberOfTokensMinted()).to.eq(5);

    for (let i = 0; i < 5; i++) {
      const ret = await bnbDisk.tokenCount(i+1, accountList[i].address);
      console.log("tokenCount for ", i+1, ret[0] as BigNumber)

      expect (ret[0] as BigNumber).to.equal(50);
      expect(await bnbDisk.tokenPrice(i+1, accountList[i].address)).to.equal(100);
    }    
  })


  it ("NFT Buy test", async function () {
    console.log("==============Balance List=============");
    for (let i = 0; i < 5; i++) {
      console.log((i + 1), " : ", await accountList[i].getBalance());
    }

    console.log((await bnbDisk.tokenCount(2, accountList[1].address))[0] as BigNumber);

    expect((await bnbDisk.tokenCount(2, accountList[1].address))[0] as BigNumber).to.equal(50);
    // Owner buy  tokenID"2" : price : 2
    await bnbDisk.buyNFT(2, accountList[1].address, {value: 100});
    expect((await bnbDisk.tokenCount(2, accountList[1].address))[0] as BigNumber).to.equal(50 - 1);

    // // isPurchased() 
    console.log(await bnbDisk.isPurchased(2, accountList[0].address));
    expect(await bnbDisk.isPurchased(2, accountList[0].address)).equal(true);
    await expect(bnbDisk.buyNFT(2, accountList[1].address, {value: 100})).to.be.revertedWith("Already purchased");
    
    expect(await bnbDisk.isPurchased(2, accountList[4].address)).equal(false);

    // Buy revert because of "insufficient money"
    await expect(bnbDisk.connect(accountList[3]).buyNFT(2, accountList[1].address, {value: 1})).to.be.revertedWith("insufficient money");
    // // Buy revert because of "Not enough token"
    // await expect(bnbDisk.connect(accountList[5]).buyNFT(2, accountList[0].address, {value: 10})).to.be.revertedWith("Not enough token");
  })

  it ("Fee Test", async function() {
    const seller = accountList[3];
    const buyer = accountList[4];

    console.log("Seller : ", seller.address);
    console.log("Buyer : ", buyer.address);

    await bnbDisk.setTaxFee(20);
    await bnbDisk.connect(seller).setTokenPrice(4, BigNumber.from('10000000000000000000'));
    
    console.log("Contract Balance : ", await bnbDisk.provider.getBalance(bnbDisk.address));
    console.log("Seller Balance : ", await seller.getBalance());
    console.log("Buyer Balance : ", await buyer.getBalance());
   
    
    await bnbDisk.connect(buyer).buyNFT(4, seller.address, {value: BigNumber.from('10000000000000000000')});

    console.log("Contract Balance : ", await bnbDisk.provider.getBalance(bnbDisk.address));
    console.log("Seller Balance : ", await seller.getBalance());
    console.log("Buyer Balance : ", await buyer.getBalance());

  })
});