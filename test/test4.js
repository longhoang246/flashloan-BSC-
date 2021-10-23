const BN = require('bn.js');
const { assert } = require('console');
const IERC20 = artifacts.require('IERC20')
function cast(x) {
    if (x instanceof BN) {
      return x;
    }
    return new BN(x);
  }

function pow(x, y) {
    x = cast(x);
    y = cast(y);
    return x.pow(y);
  }

function sendEther(web3, from, to, amount) {
    return web3.eth.sendTransaction({
      from,
      to,
      value: web3.utils.toWei(amount.toString(), "ether"),
    });
  }
const amount = pow(10,6).mul(new BN('100000'));
const amount1 = pow(10,6).mul(new BN('10000'));
const whale = '0xE30D674E46EaE016F85217515b69c3283AC6D625';

const FlashLoan = artifacts.require('FlashLoan');

contract('FlashLoan', (accounts)=>{

    beforeEach(async ()=>{
        token = await IERC20.at('0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47');
        flash = await FlashLoan.new();
        const bal = await token.balanceOf(whale);
        assert(bal.gte(amount1),'whale suck')
        await sendEther(web3,accounts[0], whale,1);
        await token.transfer(flash.address,amount,{
            from: whale
        })
    })

    it('test sit',async () =>{
        const tx = await flash.testFlashSwap(['0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47','0x55d398326f99059fF775485246999027B3197955'],amount,1,['0x3EE2200Efb3400fAbB9AacF31297cBdD1d435D47','0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56'], pow(10,6).mul(new BN('200000')), pow(10,6).mul(new BN('100000')));
        console.log(tx)
        for (const log of tx.logs) {
            console.log(log.args.message, log.args.val.toString())
        }
    })
})