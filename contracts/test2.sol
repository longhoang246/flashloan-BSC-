// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './interfaces/IPancakeFactory.sol';


contract PCPrice {
    using SafeMath for uint;
    

    IPancakeFactory pcs2f = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    
    IPancakeFactory biswapf = IPancakeFactory(0x858E3312ed3A876947EA49d572A7C42DE08af7EE);
    
    

    function getOut(uint _amountIn, address _token0, address _token1, address _tokenIn, uint _choose) public view returns(uint){
        IPancakeFactory _factory = _choose == 1 ? pcs2f : biswapf;
        address _pairAddress = _factory.getPair(_token0, _token1);
        IERC20 _token0_ = IERC20(_token0);
        IERC20 _token1_ = IERC20(_token1);
        uint[] memory reserve = new uint[](4);
        reserve[0] = _token0_.balanceOf(_pairAddress);
        reserve[1] = _token1_.balanceOf(_pairAddress);
        (reserve[2], reserve[3]) = _tokenIn == _token0 ? (reserve[0],reserve[1]) : (reserve[1],reserve[0]);
        uint amountInWithFee = _amountIn.mul(9975);
        uint numerator = amountInWithFee.mul(reserve[3]);
        uint denomerator = reserve[2].mul(10000).add(amountInWithFee);
        uint amountOut = numerator/denomerator;
        return amountOut;
    }

    function getAmountsOut(uint _amountIn, address[] memory path, uint _choose) public view returns (uint[] memory amounts) {
        require(path.length >= 2, 'PancakeLibrary: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = _amountIn;
        for (uint i; i < path.length - 1; i++) {
            amounts[i + 1] = getOut(amounts[i],path[i],path[i+1], path[i], _choose);
        }
        return amounts;
    }

}