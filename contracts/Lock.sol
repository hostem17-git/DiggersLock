// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// TODO: Leave Staked DIG in the contract only or to do anything with it?

// Import this file to use console.log
import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "./IERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Lock is Ownable, ReentrancyGuard, ERC1155Receiver {
    mapping(address => uint256) public amountStaked;
    mapping(address => uint256) public firstStakeTime;
    mapping(address => uint256) public NFTLockCount;

    uint256 minimumLockingPeriod;
    uint256 minimumStakeAmount;

    address public diggersAddress;
    address public diggersNFTAddress;
    address public rewards;

    IERC20 public Diggers;
    IERC1155Burnable public DiggersNFT;

    constructor(
        address _diggers,
        address _diggersNFT,
        uint256 _minimumStakeAmount,
        uint256 _minimumLockingPeriod
    ) {
        diggersAddress = _diggers;
        minimumStakeAmount = _minimumStakeAmount;
        minimumLockingPeriod = _minimumLockingPeriod;
        Diggers = IERC20(_diggers);
        DiggersNFT = IERC1155Burnable(_diggersNFT);
    }

    function StakeDig(uint256 _amount) external {
        require(
            _amount >= minimumStakeAmount,
            "Diggers:Not enough Dig provided"
        );
        Diggers.transferFrom(msg.sender, address(this), _amount);

        if (amountStaked[msg.sender] == 0) {
            firstStakeTime[msg.sender] = block.timestamp;
        }

        amountStaked[msg.sender] += _amount;
    }

    function WithDrawDig(uint256 _amount) external nonReentrant {
        require(
            block.timestamp >=
                firstStakeTime[msg.sender] + minimumLockingPeriod,
            "Diggers:Must wait minimum locking time before withdrawing Dig"
        );
        require(
            amountStaked[msg.sender] >= _amount,
            "Diggers:Not enough Dig staked"
        );

        amountStaked[msg.sender] -= _amount;

        Diggers.transferFrom(address(this), msg.sender, _amount);
    }

    function LockNFT(
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public {
        NFTLockCount[msg.sender] += _amount;

        DiggersNFT.safeTransferFrom(
            msg.sender,
            address(this),
            _id,
            _amount,
            _data
        );
    }

    function burnNFT(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external onlyRewards {
        NFTLockCount[msg.sender] -= _amount;
        DiggersNFT.burn(_from, _id, _amount);
    }

    function setRewards(address _rewards) external onlyOwner {
        rewards = _rewards;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    modifier onlyRewards() {
        require(msg.sender == rewards, "Diggers:Not Authorised");
        _;
    }
}
