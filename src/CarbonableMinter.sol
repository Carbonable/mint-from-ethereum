//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/Context.sol";
import "@openzeppelin/access/Ownable.sol";
import "@openzeppelin/token/ERC20/IERC20.sol";
import "src/interfaces/IStarknetMessaging.sol";

contract CarbonableMinter is Context, Ownable {
    /// EVENTS
    event L2MintTriggered(
        address indexed _sender,
        uint256 _l2RecipientAddress,
        uint256 _l2ProjectAddress,
        uint256 _value,
        uint256 _timestamp
    );

    /// ERRORS
    error L2ParametersNotSet();
    error L2ParameterIsZero();
    error AllowanceTooLow();
    error TransferFailed();
    error WithdrawFailed();

    /// STORAGE
    // Address of StarkNetMessaging contract
    IStarknetMessaging private _starknetMessaging;
    // Selector of the mint function
    uint256 private _mintSelector;
    // Address of the USDC token contract
    IERC20 private constant USDC =
        IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

    /// MODIFIERS
    modifier onlyIfL2ParametersSet() {
        if (_mintSelector == 0) {
            revert L2ParametersNotSet();
        }
        _;
    }

    constructor(uint256 mintSelector_, address starknetMessaging_) {
        _mintSelector = mintSelector_;
        _starknetMessaging = IStarknetMessaging(starknetMessaging_);
    }

    function configureL2Parameters(uint256 mintSelector_) public onlyOwner {
        if (mintSelector_ == 0) {
            revert L2ParameterIsZero();
        }

        _mintSelector = mintSelector_;
    }

    function mintOnL2(
        uint256 l2RecipientAddress,
        uint256 l2ProjectAddress,
        uint256 value,
        uint256 amount
    ) public onlyIfL2ParametersSet {
        address sender = _msgSender();
        if (USDC.allowance(sender, address(this)) < amount) {
            revert AllowanceTooLow();
        }

        // Transfer USDC from sender to this contract
        bool sent = USDC.transferFrom(sender, address(this), amount);
        if (!sent) {
            revert TransferFailed();
        }

        // Send L2 Message
        uint256[] memory payload = new uint256[](3);
        payload[0] = l2RecipientAddress;
        payload[1] = value;
        payload[2] = amount;
        _starknetMessaging.sendMessageToL2(
            l2ProjectAddress,
            _mintSelector,
            payload
        );

        // Emit L1 Event
        emit L2MintTriggered(
            msg.sender,
            l2RecipientAddress,
            l2ProjectAddress,
            value,
            block.timestamp
        );
    }

    function withdrawUSDC() public onlyOwner {
        uint256 amount = USDC.balanceOf(address(this));
        bool sent = USDC.transfer(owner(), amount);
        if (!sent) {
            revert WithdrawFailed();
        }
    }
}
