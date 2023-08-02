use ethereum_minter::ethereum_minter::EthereumMinter::BookingStatus;
use traits::Into;
use option::OptionTrait;

fn mint_status_to_u8(status: BookingStatus) -> u8 {
    match status {
        BookingStatus::Booked(()) => 0,
        BookingStatus::Failed(()) => 1,
        BookingStatus::Minted(()) => 2,
        BookingStatus::Refunded(()) => 3,
    }
}

fn u8_to_mint_status(status: u8) -> Option<BookingStatus> {
    if status == 0_u8 {
        Option::Some(BookingStatus::Booked(()))
    } else if status == 1_u8 {
        Option::Some(BookingStatus::Failed(()))
    } else if status == 2_u8 {
        Option::Some(BookingStatus::Minted(()))
    } else if status == 3_u8 {
        Option::Some(BookingStatus::Refunded(()))
    } else {
        Option::None(())
    }
}

