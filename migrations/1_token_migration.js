var Token = artifacts.require("DEARToken");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(Token,"DEAR Token","DEAR","100000000000000000000000000000");
};