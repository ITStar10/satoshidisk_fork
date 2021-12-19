import chai from "chai"
import chaiAsPromised from "chai-as-promised"
import { solidity } from 'ethereum-waffle'
import { expect } from "chai"
import { ethers } from "hardhat"

import { SatoToken, SatoToken__factory } from "../typechain";
import { Address } from "cluster"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
chai.use(solidity)
chai.use(chaiAsPromised)

describe ("SatoToken", function() {
  let satoToken : SatoToken;
  // let owner : SignerWithAddress, accnt1 : SignerWithAddress, accnt2 : SignerWithAddress;

  let accountList : SignerWithAddress[];
  let owner : SignerWithAddress;

  this.beforeAll(async function () {
    // [owner, accnt1, accnt2] = await ethers.getSigners()
    accountList = await ethers.getSigners();
    owner = accountList[0];
    
    const SatoToken = await ethers.getContractFactory("SatoToken");
    satoToken = await SatoToken.deploy();

    console.log("===========Account List==========");
    accountList.forEach((item, index) => {
      console.log(item.address)

      satoToken.mintNFT(
        item.address,
        "TestURI- " + index,
        index * 100,
        "Optional Description : " + index
      )
    });
  });

  it ("SatoToken mint nft items", async function() {
    expect(await satoToken.getNumberOfTokensMinted()).to.eq(accountList.length);

    for (let i = 0; i < accountList.length; i++) {
      // console.log("Owner of ", (i+1), " : ", await satoToken.ownerOf(i+1));
      expect(await satoToken.ownerOf(i+1)).to.equal(accountList[i].address);
    }    
  })

  it ("NFT Buy test", async function () {
    console.log("==============Befor================");
    // console.log("Seller Balance : ", await accountList[1].getBalance());
    // console.log("Buyer Balance : ", await owner.getBalance());
    accountList.forEach(async (item, index) => console.log(index, " : ", await item.getBalance()));

    expect(await satoToken.ownerOf(2)).to.equal(accountList[1].address);
    satoToken.buyNFT(2, {value: 200});

    await satoToken.connect(accountList[4]).buyNFT(8, {value: 800});
    // await expect(satoToken.connect(accountList[2].address).buyNFT(2, {value: 200}));
    // expect(await satoToken.ownerOf(2)).to.equal(accountList[2].address);

    await satoToken.connect(accountList[5]).buyNFT(1, {value: 100});

    // Failed if money insufficient
    await expect(satoToken.connect(accountList[3]).buyNFT(2, {value: 1})).to.be.revertedWith("insufficient money to buy");

    console.log("==============After================");
    accountList.forEach(async (item, index) => console.log(index, " : ", await item.getBalance()));

    // Failed if money insufficient
    await expect(satoToken.connect(accountList[3]).buyNFT(7, {value: 1})).to.be.revertedWith("insufficient money to buy");

  })
});