const test2 = artifacts.require("PCPrice");
const test3 = artifacts.require('FlashLoan');
const test4 = artifacts.require('Multicall');

module.exports = function (deployer) {
  deployer.deploy(test2);
  deployer.deploy(test3);
  deployer.deploy(test4);
  
};
