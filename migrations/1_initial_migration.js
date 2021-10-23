const test2 = artifacts.require("PCPrice");
const test3 = artifacts.require('FlashLoan');
module.exports = function (deployer) {
  deployer.deploy(test2);
  deployer.deploy(test3);
};
