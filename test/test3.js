const PCPrice = artifacts.require('PCPrice');
const multicall = artifacts.require('Multicall');


contract('PCPRice',()=>{

    before(async function(){
        

    });
    it('view Out ',async()=>{
        const pcs = await PCPrice.deployed();
        console.log(pcs)
        console.log(pcs.contract.methods.getAmountsOut)
        console.log(pcs.getAmountsOut.call)
        const pcs1 = await pcs.getAmountsOut.call(1,['0x7130d2A12B9BCbFAe4f2634d864A1Ee1Ce3Ead9c','0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56','0x55d398326f99059fF775485246999027B3197955'],1);
        console.log(pcs1)
        
        const mc = await multicall.deployed();

        const mclog = await mc.aggregate.call([{target: pcs.address, 
        callData: "0x4955796c00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000030000000000000000000000007130d2a12b9bcbfae4f2634d864a1ee1ce3ead9c000000000000000000000000e9e7cea3dedca5984780bafc599bd69add087d5600000000000000000000000055d398326f99059ff775485246999027b3197955"}]);
        console.log(mclog);
    })
})