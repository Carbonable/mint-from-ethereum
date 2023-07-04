use ethereum_minter::ethereum_minter::EthereumMinter::MintStatus;
use traits::Into;
use option::OptionTrait;

fn mint_status_to_u8(status: MintStatus) -> u8 {
    match status {
        MintStatus::Booked(()) => 0,
        MintStatus::Failed(()) => 1,
        MintStatus::Minted(()) => 2,
        MintStatus::Refunded(()) => 3,
    }
}

fn u8_to_mint_status(status: u8) -> Option<MintStatus> {
    if status == 0_u8 {
        Option::Some(MintStatus::Booked(()))
    } else if status == 1_u8 {
        Option::Some(MintStatus::Failed(()))
    } else if status == 2_u8 {
        Option::Some(MintStatus::Minted(()))
    } else if status == 3_u8 {
        Option::Some(MintStatus::Refunded(()))
    } else {
        Option::None(())
    }
}

