use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IVault<TContractState> {
    fn batch_getter(self: @TContractState, projectAddress: Array<ContractAddress>) -> ();
}

#[starknet::contract]
mod Vault {
    use starknet::ContractAddress;

    #[storage]
    struct Storage {}

    // Externals
    #[abi(embed_v0)]
    impl VaultImpl of super::IVault<ContractState> {
        fn batch_getter(self: @ContractState, projectAddress: Array<ContractAddress>) -> () {
            ()
        }
    }
}
