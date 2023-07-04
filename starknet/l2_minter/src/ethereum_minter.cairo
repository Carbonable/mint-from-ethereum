#[starknet::contract]
mod EthereumMinter {
    // Library Imports
    use starknet::class_hash::ClassHash;
    use zeroable::Zeroable;
    use starknet::ContractAddress;
    use starknet::get_block_timestamp;
    use core::option::OptionTrait;
    use result::ResultTrait;
    use traits::{Into, TryInto};

    // use ethereum_minter::helpers::booking_storage::StorageAccessBooking;
    use ethereum_minter::helpers::status::mint_status_to_u8;
    use ethereum_minter::helpers::status::u8_to_mint_status;
    // use ethereum_minter::interfaces::l1_minter::IEthereumMinter;
    use ethereum_minter::interfaces::erc3525::{IERC3525Dispatcher, IERC3525DispatcherTrait};

    #[derive(storage_access::StorageAccess, Drop, Copy)]
    struct Booking {
        value: u256,
        amount: u256,
        status: u8,
    }

    #[derive(storage_access::StorageAccess, Drop)]
    enum MintStatus {
        Booked: (),
        Failed: (),
        Minted: (),
        Refunded: (),
    }

    #[storage]
    struct Storage {
        _l1_minter_address: felt252,
        _l1_mint_counts: LegacyMap::<ContractAddress, u32>,
        // booked_values: (user_address, user_mint_index) -> (value, amount, status)
        _booked_values: LegacyMap::<(ContractAddress, u32), Booking>,
        _projects_contract: IERC3525Dispatcher,
        _slot: u256,
        _unit_price: u256,
        _max_supply: u256,
        _max_value_per_tx: u256,
        _min_value_per_tx: u256,
        _remaining_supply: u256,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Upgraded: Upgraded,
        BookingClaimed: BookingClaimed,
        BookingHandled: BookingHandled,
    }

    #[derive(Drop, starknet::Event)]
    struct Upgraded {
        implementation: ClassHash
    }

    #[derive(Drop, starknet::Event)]
    struct BookingHandled {
        address: ContractAddress,
        value: u256,
        time: u64
    }

    #[derive(Drop, starknet::Event)]
    struct BookingClaimed {
        address: ContractAddress,
        value: u256,
    }

    // Methods
    #[constructor]
    fn init(
        ref self: ContractState,
        projects_contract: ContractAddress,
        slot: u256,
        unit_price: u256,
        max_supply: u256,
        max_value_per_tx: u256,
        min_value_per_tx: u256,
    ) {
        assert(!projects_contract.is_zero(), 'Projects contract cannot be 0');
        assert(unit_price > 0, 'Unit price must be positive');
        assert(max_supply > 0, 'Max supply must be positive');
        assert(max_value_per_tx > 0, 'Max value per tx <= 0');
        assert(min_value_per_tx > 0, 'Min value per tx <= 0');
        assert(max_value_per_tx >= min_value_per_tx, 'Max < min per tx');
        assert(max_supply >= max_value_per_tx, 'Max supply < max value per tx');
        assert(slot != 0, 'Slot cannot be zero');

        let projects = IERC3525Dispatcher { contract_address: projects_contract };
        let project_value = projects.getProjectValue(slot);
        assert(max_supply <= project_value, 'Max supply > project value');

        self._projects_contract.write(projects);
        self._slot.write(slot);
        self._unit_price.write(unit_price);
        self._max_supply.write(max_supply);
        self._max_value_per_tx.write(max_value_per_tx);
        self._min_value_per_tx.write(min_value_per_tx);
        self._remaining_supply.write(max_supply);
    }

    #[generate_trait]
    #[external(v0)]
    impl EthereumMinter of IEthereumMinter {
        fn get_l1_minter_address(self: @ContractState) -> felt252 {
            self._l1_minter_address.read()
        }

        fn sold_out(self: @ContractState) -> bool {
            self._remaining_supply.read() < self._min_value_per_tx.read()
        }

        fn claim(ref self: ContractState, user_address: ContractAddress, id: u32) {
            assert(self.sold_out(), 'Contract not sold out');

            // [Check] Booking ok;
            let mut booking = self._booked_values.read((user_address.into(), id));
            assert(
                booking.status == mint_status_to_u8(MintStatus::Booked(())), 'Booking not found'
            );

            let projects_contract = self._projects_contract.read();
            let slot = self._slot.read();

            // [Effect] Update Booking status
            booking.status = mint_status_to_u8(MintStatus::Minted(()));
            self._booked_values.write((user_address.into(), id), booking);

            // [Interaction] Mint
            let token_id = self
                ._projects_contract
                .read()
                .mintNew(user_address.into(), slot, booking.value);

            // [Effect] Emit event
            self
                .emit(
                    Event::BookingClaimed(
                        BookingClaimed { address: user_address, value: booking.value,  }
                    )
                );
        }

        fn set_l1_minter_address(ref self: ContractState, l1_address: felt252) {
            assert(!l1_address.is_zero(), 'L1 address cannot be zero');
            let _l1_address = self._l1_minter_address.read();
            assert(_l1_address.is_zero(), 'L1 address already set');
            self._l1_minter_address.write(l1_address);
        }

        fn upgrade(ref self: ContractState, impl_hash: ClassHash) {
            assert(!impl_hash.is_zero(), 'Class hash cannot be zero');
            starknet::replace_class_syscall(impl_hash).unwrap_syscall();
            self.emit(Event::Upgraded(Upgraded { implementation: impl_hash }));
        }
    }

    #[l1_handler]
    // TODO: Add L1 user address?
    fn book_value_from_l1(
        ref self: ContractState,
        from_address: felt252,
        user_address: ContractAddress,
        value: u256, // TODO: u128 enough?
        amount: u256, // TODO: u128 enough?
        time: u64, // TODO: timestamp from L1?
    ) {
        // Can only be called by L1 minter
        // This method shouldn't fail otherwise.
        assert(from_address == self._l1_minter_address.read(), 'Only L1 minter can mint value');

        // Get Booking Status
        let new_user_mint_id = self._l1_mint_counts.read(user_address) + 1_u32;
        self._l1_mint_counts.write(user_address, new_user_mint_id);
        let unit_price = self._unit_price.read();
        let remaining_supply = self._remaining_supply.read();
        let max_value_per_tx = self._max_value_per_tx.read();
        let min_value_per_tx = self._min_value_per_tx.read();

        let mut status = MintStatus::Failed(());
        if (value <= max_value_per_tx && value >= min_value_per_tx && amount == unit_price
            * value && value <= remaining_supply) {
            status = MintStatus::Booked(());
            self._remaining_supply.write(remaining_supply - value);
        }

        let u8_status = mint_status_to_u8(status);

        // Write booking
        let booking = Booking { value, amount, status: u8_status };

        self._booked_values.write((user_address, new_user_mint_id), booking);

        // [Effect] Emit event
        let time = get_block_timestamp();

        self.emit(Event::BookingHandled(BookingHandled { address: user_address, value, time }));
    }
}


#[cfg(test)]
mod tests {
    use array::ArrayTrait;
    use core::result::ResultTrait;
    use core::traits::Into;
    use option::OptionTrait;
    use starknet::syscalls::deploy_syscall;
    use traits::TryInto;

    use test::test_utils::assert_eq;

    use super::EthereumMinter;
    use ethereum_minter::interfaces::l1_minter::{
        IEthereumMinterDispatcher, IEthereumMinterDispatcherTrait
    };

    #[test]
    #[available_gas(30000000)]
    fn test_init() {
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

        let (address0, _) = deploy_syscall(
            EthereumMinter::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
        )
            .unwrap();
        let mut contract = IEthereumMinterDispatcher { contract_address: address0 };

        assert(contract.get_l1_minter_address() == 0, 'l1_minter_address == 0');
    }
}
