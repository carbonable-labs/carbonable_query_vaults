use starknet::{ContractAddress, ClassHash};
use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};

#[derive(Drop, Serde, Copy)]
struct VintageInfo {
    owner: ContractAddress,
    token_id: u256,
    balance: u256,
    year: u32,
    status: CarbonVintageType
}

#[derive(Drop, Serde, Copy)]
struct ProjectInfo {
    project: ContractAddress,
    vintage_info: Span<VintageInfo>
}

#[starknet::interface]
trait IVault<TContractState> {
    /// Get all vintage information for an array of users for a single project
    fn batch_getter(
        self: @TContractState,
        project_address: ContractAddress,
        user_addresses: Array<ContractAddress>
    ) -> Span<VintageInfo>;

    /// Get all vintage information for a single user for an array of projects
    fn get_all_user_carbon_info(
        self: @TContractState,
        user_address: ContractAddress,
        project_addresses: Array<ContractAddress>
    ) -> Span<ProjectInfo>;
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
    use super::{CarbonVintageType, VintageInfo, ProjectInfo};

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl VaultImpl of super::IVault<ContractState> {
        fn batch_getter(
            self: @ContractState,
            project_address: ContractAddress,
            user_addresses: Array<ContractAddress>
        ) -> Span<VintageInfo> {
            let mut res: Array<VintageInfo> = array![];

            let project_dispatcher = IProjectDispatcher { contract_address: project_address };
            let vintage_dispatcher = IVintageDispatcher { contract_address: project_address };

            let num_vintages = vintage_dispatcher.get_num_vintages();
            let vintages = vintage_dispatcher.get_cc_vintages();

            let mut i = 0;
            while i != user_addresses
                .len() {
                    let address = user_addresses.at(i);

                    let mut k = 0;
                    while k != num_vintages {
                        let token_id = (k + 1).into();
                        let vintage = vintages.at(k);
                        let balance = project_dispatcher.balance_of(*address, token_id);
                        res
                            .append(
                                VintageInfo {
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

        fn get_all_user_carbon_info(
            self: @ContractState,
            user_address: ContractAddress,
            project_addresses: Array<ContractAddress>
        ) -> Span<ProjectInfo> {
            let mut res: Array<ProjectInfo> = array![];

            let mut i = 0;
            while i != project_addresses
                .len() {
                    let project = project_addresses.at(i);

                    let carbon_info_arr = self.batch_getter(*project, array![user_address]);

                    res.append(ProjectInfo { project: *project, vintage_info: carbon_info_arr });

                    i += 1;
                };

            res.span()
        }
    }
}
