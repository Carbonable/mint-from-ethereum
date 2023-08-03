use core::serde::Serde;
use array::{ArrayTrait, Array};
use array::SpanTrait;
use core::result::ResultTrait;
use core::traits::Into;
use option::OptionTrait;
use starknet::syscalls::deploy_syscall;
use traits::TryInto;

use test::test_utils::assert_eq;

use ethereum_minter::ethereum_minter::EthereumMinter;
use ethereum_minter::interfaces::l1_minter::{
    IEthereumMinterDispatcher, IEthereumMinterDispatcherTrait
};

use ethereum_minter::tests::mocks::mock_project::MockProject;

use debug::PrintTrait;

#[test]
#[available_gas(30000000)]
fn test_get_l1_minter() {
    let args: Array<felt252> = Default::default();
    let l1_minter: Span<felt252> = EthereumMinter::__external::get_l1_minter_address(args.span());
    let l1_minter: felt252 = *l1_minter[0];
    l1_minter.print();
}

#[test]
#[available_gas(300000)]
fn test_set_l1_minter() {
    let mut args: Array<felt252> = Default::default();
    args.append(1337);
    assert(EthereumMinter::__external::set_l1_minter_address(args.span()).is_empty(), 'Not empty');
    let l1_minter = *(EthereumMinter::__external::get_l1_minter_address(
        Default::default().span()
    )[0]);
    assert(l1_minter == 1337, 'set_l1_minter_address failed');
}

#[test]
#[available_gas(30000000)]
fn test_initialize() {
    let mut calldata = Default::default();

    // Projects contract
    calldata.append(1);
    // Slot
    calldata.append(2);
    calldata.append(0);
    // Unit price
    calldata.append(3);
    calldata.append(0);
    // Max supply
    calldata.append(10);
    calldata.append(0);
    // Max value per tx
    calldata.append(6);
    calldata.append(0);
    // Min value per tx
    calldata.append(1);
    calldata.append(0);

    // let x = array![1];

    let (address, _) = deploy_syscall(
        EthereumMinter::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap();
    let mut contract = IEthereumMinterDispatcher { contract_address: address };

    assert(contract.get_l1_minter_address() == 0, 'l1_minter_address == 0');
}
