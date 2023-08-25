// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DecentralizedExchange is Ownable {
    IERC20 public token;

    enum OrderType { Buy, Sell }

    struct Order {
        address user;
        uint256 amount;
        uint256 price;
        OrderType orderType;
        bool isActive;
    }

    mapping(bytes32 => Order[]) public orderBook;
    mapping(address => mapping(address => uint256)) public userBalances;

    event OrderPlaced(
        address indexed user,
        OrderType indexed orderType,
        uint256 amount,
        uint256 price
    );

    event OrderCancelled(
        address indexed user,
        OrderType indexed orderType,
        uint256 amount,
        uint256 price
    );

    event TradeExecuted(
        address indexed buyer,
        address indexed seller,
        uint256 amount,
        uint256 price
    );

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function placeOrder(OrderType _orderType, uint256 _amount, uint256 _price) external {
        require(_amount > 0 && _price > 0, "Invalid order parameters");
        require(_orderType == OrderType.Buy || _orderType == OrderType.Sell, "Invalid order type");

        token.transferFrom(msg.sender, address(this), _amount);

        Order memory order = Order({
            user: msg.sender,
            amount: _amount,
            price: _price,
            orderType: _orderType,
            isActive: true
        });

        bytes32 orderHash = keccak256(abi.encodePacked(msg.sender, _amount, _price, block.timestamp));
        orderBook[orderHash].push(order);

        emit OrderPlaced(msg.sender, _orderType, _amount, _price);
    }

    function cancelOrder(OrderType _orderType, uint256 _amount, uint256 _price) external {
        bytes32 orderHash = keccak256(abi.encodePacked(msg.sender, _amount, _price));
        Order[] storage orders = orderBook[orderHash];
        uint256 remainingAmount = _amount;

        for (uint256 i = 0; i < orders.length; i++) {
            if (remainingAmount == 0) {
                break;
            }

            if (orders[i].user == msg.sender && orders[i].isActive) {
                uint256 cancelAmount = orders[i].amount;
                if (remainingAmount >= cancelAmount) {
                    remainingAmount -= cancelAmount;
                    orders[i].isActive = false;
                } else {
                    orders[i].amount -= remainingAmount;
                    remainingAmount = 0;
                }

                emit OrderCancelled(msg.sender, _orderType, orders[i].amount, orders[i].price);
            }
        }

        require(remainingAmount == 0, "Insufficient order amount to cancel");
    }

    function executeTrade(
        uint256 _buyAmount,
        uint256 _buyPrice,
        uint256 _sellAmount,
        uint256 _sellPrice
    ) external {
        require(_buyAmount > 0 && _sellAmount > 0, "Invalid trade amounts");
        require(_buyPrice >= _sellPrice, "Invalid trade prices");

        bytes32 buyOrderHash = keccak256(abi.encodePacked(msg.sender, _buyAmount, _buyPrice));
        bytes32 sellOrderHash = keccak256(abi.encodePacked(msg.sender, _sellAmount, _sellPrice));

        Order[] storage buyOrders = orderBook[buyOrderHash];
        Order[] storage sellOrders = orderBook[sellOrderHash];

        for (uint256 i = 0; i < buyOrders.length; i++) {
            for (uint256 j = 0; j < sellOrders.length; j++) {
                if (buyOrders[i].isActive && sellOrders[j].isActive) {
                    uint256 tradeAmount = min(buyOrders[i].amount, sellOrders[j].amount);
                    uint256 tradePrice = sellOrders[j].price;

                    // Transfer tokens and update user balances
                    token.transfer(sellOrders[j].user, tradeAmount);
                    userBalances[sellOrders[j].user][address(token)] -= tradeAmount;
                    token.transfer(buyOrders[i].user, tradeAmount);
                    userBalances[buyOrders[i].user][address(token)] += tradeAmount;

                    emit TradeExecuted(buyOrders[i].user, sellOrders[j].user, tradeAmount, tradePrice);

                    // Update order amounts and isActive status
                    buyOrders[i].amount -= tradeAmount;
                    sellOrders[j].amount -= tradeAmount;

                    if (buyOrders[i].amount == 0) {
                        buyOrders[i].isActive = false;
                    }

                    if (sellOrders[j].amount == 0) {
                        sellOrders[j].isActive = false;
                    }
                }
            }
        }
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        token.transferFrom(msg.sender, address(this), _amount);
        userBalances[msg.sender][address(token)] += _amount;
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Invalid amount");
        require(userBalances[msg.sender][address(token)] >= _amount, "Insufficient balance");

        userBalances[msg.sender][address(token)] -= _amount;
        token.transfer(msg.sender, _amount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
