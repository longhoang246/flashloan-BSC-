pragma solidity 0.8.1;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IPancakeCallee.sol';
import './interfaces/IPancakeFactory.sol';
import './interfaces/IPancakeRouter.sol';
import './interfaces/IPancakePair.sol';

import './interfaces/IBiswapCallee.sol';
import './interfaces/IBiswapFactory.sol';
import './interfaces/IBiswapRouter02.sol';
import './interfaces/IBiswapPair.sol';

contract FlashLoan is IPancakeCallee {
    IPancakeFactory factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    IPancakeRouter02 router2 = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IPancakeRouter01 router1 = IPancakeRouter01(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    receive() external payable {}

    event Log(string message, uint val);

    function testFlashSwap(address _tokenBorrow, uint _amount) external {
        address pair = factory.getPair(_tokenBorrow, WBNB);
        require(pair != address(0), "!pair");

        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // need to pass some data to trigger PancakeCall
        bytes memory data = abi.encode(_tokenBorrow, _amount);

        IPancakePair(pair).swap(amount0Out, amount1Out, address(this), data);
    }


    function pancakeCall(address _sender, uint amount0, uint amount1, bytes calldata _data) external override {
        address token0 = IPancakePair(msg.sender).token0();
        address token1 = IPancakePair(msg.sender).token1();
        address pair = factory.getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));

        // about 0.3%
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        // do stuff here
        emit Log("amount", amount);
        emit Log("amount0", amount0);
        emit Log("amount1", amount1);
        emit Log("fee", fee);
        emit Log("amount to repay", amountToRepay);

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }
}