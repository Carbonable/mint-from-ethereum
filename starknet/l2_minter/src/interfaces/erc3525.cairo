use starknet::ContractAddress;

#[starknet::interface]
trait IERC3525<TContractState> {
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn getProjectValue(self: @TContractState, slot: u256) -> u256;
    // TODO: see if `to` could be of type ContractAddress
    fn mintNew(ref self: TContractState, to: felt252, slot: u256, value: u256) -> u256;
}
