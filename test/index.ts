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
    accountList.forEach(async (item, index) => {
      console.log(index, " - ", item.address)

      await satoToken.mintNFT(
        item.address,
        "TestURI- " + index,
        (index + 1) * 1, // Price
        (index + 1) * 100, // Count
      )
    });
  });

  it ("SatoToken mint nft items", async function() {
    expect(await satoToken.getNumberOfTokensMinted()).to.eq(accountList.length);

    for (let i = 0; i < accountList.length; i++) {
      // console.log("tokenCount for ", i+1, await satoToken.tokenCount(i+1, accountList[i].address));
      expect(await satoToken.tokenCount(i+1, accountList[i].address)).to.equal((i+1) * 100);
      expect(await satoToken.tokenPrice(i+1, accountList[i].address)).to.equal(i+1);
    }    
  })

  it ("NFT Buy test", async function () {
    console.log("==============Balance List=============");
    accountList.forEach(async (item, index) => console.log(index, " : ", await item.getBalance()));

    expect(await satoToken.tokenCount(2, accountList[1].address)).to.equal(200);
    // Owner buy  tokenID"2" : count 3 = pric : 2 * 3 = 6
    let count = ethers.BigNumber.from(3);
    satoToken.buyNFT(2, accountList[1].address, count, {value: 6});
    expect(await satoToken.tokenCount(2, accountList[1].address)).to.equal(200 - 3);

    // Account[2] buy tokenID"2" from account[1] : count 5 = price : 2 * 5 = 10
    await satoToken.connect(accountList[2]).buyNFT(2, accountList[1].address, ethers.BigNumber.from(5), {value: 10});
    expect(await satoToken.tokenCount(2, accountList[1].address)).to.equal(200 - 3 - 5);

    // Buy revert because of "insufficient money"
    await expect(satoToken.connect(accountList[2]).buyNFT(2, accountList[1].address, ethers.BigNumber.from(5), {value: 1})).to.be.revertedWith("insufficient money");
    // Buy revert because of "Not enough token"
    await expect(satoToken.connect(accountList[2]).buyNFT(2, accountList[0].address, ethers.BigNumber.from(5), {value: 10})).to.be.revertedWith("Not enough token");
  })
});