const DEARToken = artifacts.require("DEARToken");
const usdt = artifacts.require("USDT");

contract("DEARToken", (accounts) => {
  it("should put 80000000000 MetaCoin in the first account", async () => {
    const dearInstance = await DEARToken.deployed();
    const usdtInstance = await usdt.deployed();
    const balance = await dearInstance.balanceOf(accounts[0]);
    console.log(balance.toNumber())
    assert.equal(String(balance), '80000000000000000000000000000000000000', "10000 wasn't in the first account");
  });
});
