var Token = artifacts.require("DEARToken");
var usdt = artifacts.require("USDT");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(usdt,"USDT Token","USDT","100000000000000000000000000000").then(()=>{
    return deployer.deploy(Token,"DEAR Token","DEAR","100000000000000000000000000000",usdt.address);
  })
};