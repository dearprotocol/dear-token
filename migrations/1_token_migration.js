// var Token = artifacts.require("DEARToken");
var Vesting = artifacts.require("VestingContract");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(Vesting)
  // deployer.deploy(Token,"DEAR Token","DEAR","100000000000000000000000000000",usdt.address);

};