// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {BobWrappedBtc} from "./Wrapped.sol";

contract Bridge {
    uint256 public number;
    uint256 public collateralThreshold;
    uint256 nextOrderId;
    mapping(uint256 => Order) public orders; // cant have struct as key, nor tupple
    mapping(address => uint256) public suppliedCollateral;
    uint256 totalCollateral;
    BobWrappedBtc wrapped = new BobWrappedBtc();

    struct Order {
        bool open; // actually redundant now that we have accepterAddress
        uint256 amountZbtc;
        uint256 amountBtc;
        address requesterAddress;
        address accepterAddress;
        BitcoinAddress bitcoinAddress;
    }

    struct BitcoinAddress {
        uint256 bitcoinAddress; // todo: use the right type
    }

    struct TransactionProof {
        // todo: fields here
        uint256 dummy;
    }

    constructor(uint256 threshold) {
        collateralThreshold = threshold;
    }

    /// lock COL in exchange for zBTC and cCOL
    function mint() public payable {
        uint256 collateral = msg.value; // this is the amount of eth sent to the contract
        uint256 mintedAmount = colToBtc(collateral) / collateralThreshold;
        wrapped.sudoMint(msg.sender, mintedAmount);

        suppliedCollateral[msg.sender] += collateral;
        totalCollateral += collateral;
    }

    /// request zBTC to be redeemed for given amount of BTC.
    function requestSwap(uint256 amountZbtc, uint256 amountBtc, BitcoinAddress calldata bitcoinAddress) public {
        // lock Zbtc by transfering it to the contract address
        wrapped.sudoTransferFrom(msg.sender, address(this), amountZbtc);
        require(amountZbtc != 0);

        uint256 id = nextOrderId++;
        orders[id] = Order({
            open: true,
            amountZbtc: amountZbtc,
            amountBtc: amountBtc,
            requesterAddress: msg.sender,
            accepterAddress: address(0),
            bitcoinAddress: bitcoinAddress
        });
    }

    function acceptSwap(uint256 id) public {
        Order storage order = orders[id];
        require(order.open);

        // todo: protocol should probably require some sort of collateral deposit here

        order.open = false;
        order.accepterAddress = msg.sender;
    }

    // not documented, but presumably required
    function cancelSwap(uint256 id) public {
        Order storage order = orders[id];
        require(order.requesterAddress == msg.sender);
        // ensure the request was not accepted yet
        require(order.accepterAddress == address(0));

        delete orders[id];
    }

    function executeSwap(uint256 id, TransactionProof calldata transactionProof) public {
        // todo: check proof

        // move the zbtc thta was locked to whoever accepted the order
        Order storage order = orders[id];

        // check that the storage item exists and has been accepted
        require(!order.open);
        require(order.amountZbtc != 0);

        wrapped.transfer(order.accepterAddress, order.amountZbtc);

        // clean up storage
        delete orders[id];
    }

    function liquidate(uint256 amountZbtc) public {
        // burn the zbtc erc20
        wrapped.sudoBurnFrom(msg.sender, amountZbtc);

        // transfer eth to caller
        uint256 collateral = btcToCol(amountZbtc);
        address payable callerAddress = payable(msg.sender);
        callerAddress.transfer(collateral);
    }

    function withdraw() public {
        uint256 totalZbtc = wrapped.totalSupply();
        uint256 requiredCol = btcToCol(totalZbtc * collateralThreshold);
        uint256 colFree = totalCollateral - requiredCol;
        uint256 withdrawal = colFree < suppliedCollateral[msg.sender] ? colFree : suppliedCollateral[msg.sender];
        suppliedCollateral[msg.sender] -= withdrawal;
        totalCollateral -= withdrawal;
    }

    function colToBtc(uint256 collateral) internal pure returns (uint256) {
        return collateral / 5; // todo
    }

    function btcToCol(uint256 collateral) internal pure returns (uint256) {
        return collateral * 5; // todo
    }
}
