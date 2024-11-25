use starknet::{ContractAddress, ClassHash};
use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};

#[derive(Drop, Serde)]
struct CarbonInfo {
    owner: ContractAddress,
    token_id: u256,
    balance: u256,
    year: u32,
    status: CarbonVintageType
}

#[starknet::interface]
trait IVault<TContractState> {
    fn batch_getter(self: @TContractState, addresses: Array<ContractAddress>) -> Span<CarbonInfo>;
}

#[starknet::contract]
mod Vault {
    use starknet::ContractAddress;
    use carbon_v3::components::vintage::interface::{
        IVintage, IVintageDispatcher, IVintageDispatcherTrait
    };
    use carbon_v3::contracts::project::{
        Project, IExternalDispatcher as IProjectDispatcher,
        IExternalDispatcherTrait as IProjectDispatcherTrait
    };
    use super::{CarbonVintageType, CarbonInfo};

    #[storage]
    struct Storage {
        project_address: ContractAddress,
    }

    // Constructor
    #[constructor]
    fn constructor(ref self: ContractState, project_address: ContractAddress) {
        self.project_address.write(project_address);
    }

    #[abi(embed_v0)]
    impl VaultImpl of super::IVault<ContractState> {
        fn batch_getter(
            self: @ContractState, addresses: Array<ContractAddress>
        ) -> Span<CarbonInfo> {
            let mut res: Array<CarbonInfo> = array![];

            let project_dispatcher = IProjectDispatcher {
                contract_address: self.project_address.read()
            };
            let vintage_dispatcher = IVintageDispatcher {
                contract_address: self.project_address.read()
            };

            let num_vintages = vintage_dispatcher.get_num_vintages();
            let vintages = vintage_dispatcher.get_cc_vintages();

            let mut i = 0;
            while i != addresses
                .len() {
                    let address = addresses.at(i);

                    let mut k = 0;
                    while k != num_vintages {
                        let token_id = (k + 1).into();
                        let vintage = vintages.at(k);
                        let balance = project_dispatcher.balance_of(*address, token_id);
                        res
                            .append(
                                CarbonInfo {
                                    owner: *address,
                                    token_id,
                                    balance,
                                    year: *vintage.year,
                                    status: *vintage.status
                                }
                            );
                        k += 1;
                    };

                    i += 1;
                };

            res.span()
        }
    }
}
