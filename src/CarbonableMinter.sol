//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/access/Ownable.sol";
import "src/interfaces/IStarknetMessaging.sol";

contract CarbonableMinter is Ownable {
    /// EVENTS
    event L2MintTriggered(
        address indexed _sender,
        uint256 _l2RecipientAddress,
        uint256 _projectAddress,
        uint256 _slotID,
        uint256 _timestamp
    );

    /// ERRORS
    error L2ParametersNotSet();

    /// STORAGE
    // Address of StarkNetMessaging contract
    IStarknetMessaging private _starknetMessaging;
    // Address of the Minter contract on L2
    uint256 private _l2MinterContract;
    // Selector of the mint function
    uint256 private _mintSelector;

    /// MODIFIERS
    modifier onlyIfL2ParametersSet() {
        if (_l2MinterContract == 0 || _mintSelector == 0) {
            revert L2ParametersNotSet();
        }
        _;
    }

    constructor(
        uint256 l2MinterContract_,
        uint256 mintSelector_,
        address starknetMessaging_
    ) {
        _l2MinterContract = l2MinterContract_;
        _mintSelector = mintSelector_;
        _starknetMessaging = IStarknetMessaging(starknetMessaging_);
    }

    function configureL2Parameters(
        uint256 l2MinterContract_,
        uint256 mintSelector_
    ) public onlyOwner {
        require(
            mintSelector_ != 0 && l2MinterContract_ != 0,
            "CarbonableMinter: L2 parameters cannot be 0"
        );
        _l2MinterContract = l2MinterContract_;
        _mintSelector = mintSelector_;
    }

    //TODO: check which project to call
    function mintOnL2(
        uint256 l2RecipientAddress_,
        uint256 projectAddress_,
        uint256 slotID_
    ) public onlyIfL2ParametersSet {
        //TODO: check if msg.value is enough
        //TODO: check amount (min max etc)
        //TODO: what if failed?

        // Send L2 Message
        uint256[] memory payload = new uint256[](3);
        payload[0] = l2RecipientAddress_;
        payload[1] = projectAddress_;
        payload[2] = slotID_;
        _starknetMessaging.sendMessageToL2(
            _l2MinterContract,
            _mintSelector,
            payload
        );

        // Emit L1 Event
        emit L2MintTriggered(
            msg.sender,
            l2RecipientAddress_,
            projectAddress_,
            slotID_,
            block.timestamp
        );
    }
}
