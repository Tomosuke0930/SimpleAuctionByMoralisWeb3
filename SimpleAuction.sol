// SPDX-License-Identifier: GPL-2.0
pragma solidity >=0.7.0 < 0.9.0;

contract SimpleAuction {
    // Parameters of the SimpleAuction
    address payable public beneficiary; //owner
    uint public auctionEndTime;

    // Current state of the auctionEndTime
    address public highestBidder;
    uint public highestBid;

    mapping(address => uint) public pendingReturns;

    bool ended = false;

    event HighestBidIncrease(address bidder, uint amount);
    event AucitionEnded(address winner, uint amount);

    // bid:入札, biddingTime:入札できる時間(秒) beneficiary: オークション主催者,
    constructor(uint _biddingTime, address payable _beneficiary) {
        beneficiary = _beneficiary;
        auctionEndTime = block.timestamp + _biddingTime;
    }

    //入札するための関数
    function bid() public payable {
        if(block.timestamp > auctionEndTime) {
            revert ("The auction has already ended");
        }

        if(msg.value <= highestBid) {
            revert("There is already a higher or equal bid");
        }

        // この時点で、オークションで競り負けた人が存在する。
        // ここでmapping,pendingReturnsに直前までhighestBidderだった人のアドレスがmappingに追加。
        // よって入札に負けた人だけのアドレスと入札額が紐づいたmappingが作られる
        if(highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        // ここでhighestBidder,highestBidが更新される
        highestBidder = msg.sender;
        highestBid = msg.value;
        emit HighestBidIncrease(msg.sender, msg.value);
    }

    //引き出す関数
    function withdraw() public returns(bool) {
        uint amount = pendingReturns[msg.sender];
        if(amount > 0) {
            pendingReturns[msg.sender] = 0;

            if(!payable(msg.sender).send(amount)) {
                pendingReturns[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function auctionEnd() public {
        if(block.timestamp < auctionEndTime) {
            revert ("The auction has not ended yet");
        }

        if(ended) {
            revert("The function auctionEnded has already been called");
        }

        ended = true;
        emit AucitionEnded(highestBidder, highestBid);
        
        beneficiary.transfer(highestBid);
    }

    //+1

    function getRestTime() public view returns(uint) {
        return auctionEndTime - block.timestamp;
    }
}