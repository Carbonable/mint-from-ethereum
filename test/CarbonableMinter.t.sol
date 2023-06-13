// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/CarbonableMinter.sol";
import "src/interfaces/IStarknetMessaging.sol";

contract CarbonableMinterTest is Test {
    /// CONSTANTS
    address constant STARKNET_MESSAGING_ADDRESS =
        0xc662c410C0ECf747543f5bA90660f6ABeBD9C8c4;
    uint256 constant L2_MINTER_CONTRACT = 1;
    uint256 constant MINT_SELECTOR =
        453167574301948615256927179001098538682611778866623857597439531518333154691;
    uint256 constant PROJECT_L2_ADDRESS = 1002;
    uint256 constant PROJECT_L2_SLOT_ID = 2;

    address constant USER_1_L1_ADDRESS = address(1001);
    uint256 constant USER_1_L2_ADDRESS = 2001;
    address constant UNKNOWN_USER = address(0);
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    /// FIELDS
    CarbonableMinter minterL1;

    /// EVENTS
    event L2MintTriggered(
        address indexed _sender,
        uint256 _l2RecipientAddress,
        uint256 _l2ProjectAddress,
        uint256 _value,
        uint256 _timestamp
    );

    function setUp() public {
        minterL1 = new CarbonableMinter(
            MINT_SELECTOR,
            STARKNET_MESSAGING_ADDRESS
        );
        // minterL1.configureL2Parameters(MINT_SELECTOR, L2_MINTER_CONTRACT);
    }

    function testConfigureL2ParametersCannotBeZero() public {
        vm.expectRevert(CarbonableMinter.L2ParameterIsZero.selector);
        minterL1.configureL2Parameters(0);
    }

    function testConfigureL2ParametersOnlyCallableByOwner() public {
        CarbonableMinter notConfiguredMinterL1 = new CarbonableMinter(
            0,
            address(0)
        );
        vm.prank(UNKNOWN_USER);
        vm.expectRevert("Ownable: caller is not the owner");
        notConfiguredMinterL1.configureL2Parameters(MINT_SELECTOR);
    }

    function testMintToL2RequireL2ParametersToBeSet() public {
        CarbonableMinter notConfiguredMinterL1 = new CarbonableMinter(
            0,
            address(0)
        );
        vm.expectRevert(CarbonableMinter.L2ParametersNotSet.selector);
        notConfiguredMinterL1.mintOnL2(
            USER_1_L2_ADDRESS,
            PROJECT_L2_ADDRESS,
            42069000000,
            42069000000 * 2
        );
    }

    function testMintOnL2() public {
        // Call with user 1 L1 address
        vm.startPrank(USER_1_L1_ADDRESS);

        // Set timestamp to 1234
        uint256 currentTimestamp = 1234;
        // Set value to 69420
        uint256 value = 69420;
        // Set amount
        uint256 amount = value * 2;

        vm.warp(currentTimestamp);

        // Mock sendMessageToL2
        vm.mockCall(
            STARKNET_MESSAGING_ADDRESS,
            abi.encodeWithSelector(IStarknetMessaging.sendMessageToL2.selector),
            abi.encode(bytes32(0))
        );
        // Mock USDC allowance and transfer
        vm.mockCall(
            USDC,
            abi.encodeWithSelector(IERC20.allowance.selector),
            abi.encode(amount)
        );
        vm.mockCall(
            USDC,
            abi.encodeWithSelector(IERC20.transferFrom.selector),
            abi.encode(1)
        );

        // Check emitted event
        vm.expectEmit(true, false, false, true, address(minterL1));
        emit L2MintTriggered(
            USER_1_L1_ADDRESS,
            USER_1_L2_ADDRESS,
            PROJECT_L2_ADDRESS,
            value,
            currentTimestamp
        );
        minterL1.mintOnL2(
            USER_1_L2_ADDRESS,
            PROJECT_L2_ADDRESS,
            value,
            value * 2
        );

        vm.stopPrank();
    }

    function testWithdrawUSDC() public {
        vm.mockCall(
            USDC,
            abi.encodeWithSelector(IERC20.transfer.selector),
            abi.encode(1)
        );
        vm.mockCall(
            USDC,
            abi.encodeWithSelector(IERC20.balanceOf.selector),
            abi.encode(911)
        );
        minterL1.withdrawUSDC();
    }
}
