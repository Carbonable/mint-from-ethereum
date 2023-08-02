#[starknet::contract]
mod MockProject {
    use ethereum_minter::interfaces::erc3525::IERC3525;

    #[storage]
    struct Storage {
        _mint_counter: u256
    }

    #[external(v0)]
    impl MockProject of IERC3525<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            'MockProject'
        }
        fn symbol(self: @ContractState) -> felt252 {
            'MockProject'
        }
        fn getProjectValue(self: @ContractState, slot: u256) -> u256 {
            u256 { low: 31337, high: 0 }
        }
        fn mintNew(ref self: ContractState, to: felt252, slot: u256, value: u256) -> u256 {
            let mint_count = self._mint_counter.read();
            let new_mint_count = mint_count + 1;
            self._mint_counter.write(new_mint_count);
            new_mint_count
        }
    }
}
