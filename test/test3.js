const PCPrice = artifacts.require('PCPrice');

contract('PCPRice',()=>{
    it('view Out ',async()=>{
        const pcs = await PCPrice.deployed();
        const pcs1 = await pcs.getAmountsOut.call(1,['0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c','0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56','0x55d398326f99059fF775485246999027B3197955'],1);
        console.log(pcs1)
    })
})