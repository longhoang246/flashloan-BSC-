pragma solidity 0.8.1;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import './interfaces/IPancakeFactory.sol';
import './interfaces/IPancakeRouter.sol';
import './interfaces/IPancakePair.sol';

import './interfaces/IBiswapCallee.sol';
import './interfaces/IBiswapFactory.sol';
import './interfaces/IBiswapRouter02.sol';
import './interfaces/IBiswapPair.sol';

contract FlashLoan is IBiswapCallee {

    IPancakeFactory factory;
    IBiswapFactory BiswapFactory;

    address owner;

    receive() external payable {}
    
    constructor (){
        owner = msg.sender;
        BiswapFactory = IBiswapFactory(0x858E3312ed3A876947EA49d572A7C42DE08af7EE); 
        factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Log(string message, uint val);

    function testFlashSwap(address[] memory _tokenBorrowPool,uint _amount, uint[] memory _from_to,uint[] memory _amountOutminFrom_To,  address[] memory pathFrom, address[] memory pathTo, uint deadline) external onlyOwner {
        require(_tokenBorrowPool.length == 2,'suc dic');      
        address _tokenBorrow = _tokenBorrowPool[0];
        address _toToken = _tokenBorrowPool[1];

        address pair = BiswapFactory.getPair(_tokenBorrow, _toToken);
        require(pair != address(0), "!pair");

        address token0 = IBiswapPair(pair).token0();
        address token1 = IBiswapPair(pair).token1();

        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // need to pass some data to trigger PancakeCall
        bytes memory data = abi.encode(_tokenBorrow, _amount, _from_to,_amountOutminFrom_To, pathFrom, pathTo ,deadline);

        IBiswapPair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function Dex0toDex1(address tokenBorrow,uint amount,address _from, address _to,uint amountOutminFrom ,uint amountOutminTo,address[] memory pathFrom, address[] memory pathTo,uint deadline) public returns(uint) {
        IPancakeRouter02 from = IPancakeRouter02(_from);
        IPancakeRouter02 to = IPancakeRouter02(_to);
        IERC20(tokenBorrow).approve(_from, amount);
        uint[] memory amounts1 = from.swapExactTokensForTokens(amount, amountOutminFrom, pathFrom, address(this), deadline);
        IERC20(pathFrom[pathFrom.length-1]).approve(_to, amounts1[amounts1.length-1]);
        uint[] memory amounts2 = to.swapExactTokensForTokens(amounts1[amounts1.length-1], amountOutminTo, pathTo, address(this), deadline);
        emit Log('amouts-out',amounts2[amounts2.length-1]);
        return amounts2[amounts2.length-1];
    }

    function BiswapCall(address _sender, uint amount0, uint amount1, bytes calldata _data) external override {
        address token0 = IBiswapPair(msg.sender).token0();
        address token1 = IBiswapPair(msg.sender).token1();
        address pair = BiswapFactory.getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");
        (address tokenBorrow, uint amount, address[] memory _from_to,uint[] memory _amountOutminFrom_To,address[] memory pathFrom, address[] memory pathTo, uint deadline ) = abi.decode(_data, (address, uint, address[],uint[], address[], address[],uint));
        // about 0.1%
        uint fee = ((amount * 1) / 999) + 1;
        uint amountToRepay = amount + fee;


        // do stuff here
        uint amountOut = Dex0toDex1(tokenBorrow, amount, _from_to[0], _from_to[1], _amountOutminFrom_To[0], _amountOutminFrom_To[1], pathFrom, pathTo, deadline);
        
        require(amountOut > amountToRepay,"poor dumb sit");

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
        
        emit Log("money left",amountOut-amountToRepay);
    }

    function withdraw(address _tokenWithdraw) public onlyOwner {
        IERC20 token = IERC20(_tokenWithdraw);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}