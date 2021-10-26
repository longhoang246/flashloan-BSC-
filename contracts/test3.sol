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
    IPancakeRouter02 router2;

    IBiswapRouter02 BiswapRouter;
    IBiswapFactory BiswapFactory;

    address WBNBAddress = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    IERC20 WBNB = IERC20(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address owner;

    receive() external payable {}
    
    constructor (){
        owner = msg.sender;
        BiswapFactory = IBiswapFactory(0x858E3312ed3A876947EA49d572A7C42DE08af7EE);
        BiswapRouter = IBiswapRouter02(0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8);

        router2 = IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        factory = IPancakeFactory(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event Log(string message, uint val);

    function testFlashSwap(address[] memory _tokenBorrowPool,uint _amount, uint _from,uint _amountOutminFrom, uint _amountOutminTo, address[] memory pathFrom, address[] memory pathTo) external onlyOwner {
        require(_tokenBorrowPool.length == 2,'suc dic');      
        address _tokenBorrow = _tokenBorrowPool[0];
        address _toToken = _tokenBorrowPool[1];

        address pair = BiswapFactory.getPair(_tokenBorrow, _toToken);
        require(pair != address(0), "!pair");

        address from = _from == 1 ? 0x10ED43C718714eb63d5aA57B78B54704E256024E: 0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8 ;
        
        address token0 = IBiswapPair(pair).token0();
        address token1 = IBiswapPair(pair).token1();

        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // need to pass some data to trigger PancakeCall
        bytes memory data = abi.encode(_tokenBorrow, _amount, from, _amountOutminFrom, _amountOutminTo, pathFrom, pathTo );

        IBiswapPair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function BiswapCall(address _sender, uint amount0, uint amount1, bytes calldata _data) external override {
        address token0 = IBiswapPair(msg.sender).token0();
        address token1 = IBiswapPair(msg.sender).token1();
        address pair = BiswapFactory.getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");
        (address tokenBorrow, uint amount, address from, uint amountOutminFrom ,uint amountOutminTo,address[] memory pathFrom, address[] memory pathTo ) = abi.decode(_data, (address, uint, address, uint,uint, address[], address[]));
        // about 0.1%
        uint fee = ((amount * 1) / 999) + 1;
        uint amountToRepay = amount + fee;


        // do stuff here

        if ( from == 0x10ED43C718714eb63d5aA57B78B54704E256024E){
            IERC20(tokenBorrow).approve(from, amount);
            uint[] memory amounts = router2.swapExactTokensForTokens(amount,amountOutminFrom,pathFrom,address(this),block.timestamp+100000);
            IERC20(pathFrom[pathFrom.length-1]).approve(0x3a6d8cA21D1CF76F653A67577FA0D27453350dD8, amounts[amounts.length-1]);
            uint[] memory amounts2 = BiswapRouter.swapExactTokensForTokens(amounts[amounts.length-1], amountOutminTo, pathTo, address(this), block.timestamp+100000);
            emit Log('amouts-out',amounts2[amounts2.length-1]);
        } else {
            IERC20(tokenBorrow).approve(from, amount);
            uint[] memory amounts = BiswapRouter.swapExactTokensForTokens(amount, amountOutminFrom, pathFrom, address(this), block.timestamp+100000);
            IERC20(pathFrom[pathFrom.length-1]).approve(0x10ED43C718714eb63d5aA57B78B54704E256024E, amounts[amounts.length-1]);
            uint[] memory amounts2 = router2.swapExactTokensForTokens(amounts[amounts.length-1], amountOutminTo,pathTo,address(this),block.timestamp+100000);
            emit Log('amouts-out',amounts2[amounts2.length-1]);
        }
        
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    function withdraw(address _tokenWithdraw) public onlyOwner {
        IERC20 token = IERC20(_tokenWithdraw);
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}