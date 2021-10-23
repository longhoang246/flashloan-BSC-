// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
interface PCS2R {
    function factory() external pure returns (address);
}


interface PCS2F {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
 


contract PCPrice {
    using SafeMath for uint;
    PCS2R pcs2r = PCS2R(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    PCS2F pcs2f = PCS2F(pcs2r.factory());
    uint public amountOut;

    function getOut(uint _amountIn, address _token0, address _token1, address _tokenIn) public returns(uint){
        address _pairAddress = pcs2f.getPair(_token0, _token1);
        ERC20 _token0_ = ERC20(_token0);
        ERC20 _token1_ = ERC20(_token1);
        uint _reserve0 = _token0_.balanceOf(_pairAddress);
        uint _reserve1 = _token1_.balanceOf(_pairAddress);
        (uint _reserveIn, uint _reserveOut) = _tokenIn == _token0 ? (_reserve0,_reserve1) : (_reserve1,_reserve0);
        uint amountInWithFee = _amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(_reserveOut);
        uint denomerator = _reserveIn.mul(10000).add(amountInWithFee);
        amountOut = numerator/denomerator;
        return amountOut;
    }

    function getAmountsOut(uint _amountIn, address[] memory path) public returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = _amountIn;
        for (uint i; i < path.length - 1; i++) {
            amounts[i + 1] = getOut(amounts[i],path[i],path[i+1], path[i]);
        }
        return amounts;
    }

}