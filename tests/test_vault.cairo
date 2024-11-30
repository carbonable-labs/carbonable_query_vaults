// Starknet deps

use starknet::{ContractAddress, contract_address_const};

// External deps

use snforge_std as snf;
use snforge_std::{ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address,};

// Models 

use carbon_v3::models::carbon_vintage::{CarbonVintage, CarbonVintageType};

// Components

use carbon_v3::components::vintage::interface::{
    IVintage, IVintageDispatcher, IVintageDispatcherTrait
};

// Contracts

use carbon_v3::contracts::project::{
    Project, IExternalDispatcher as IProjectDispatcher,
    IExternalDispatcherTrait as IProjectDispatcherTrait
};

use carbon_v3::contracts::vault::{Vault, IVaultDispatcher, IVaultDispatcherTrait};

use super::utils::{
    default_setup_and_deploy, deploy_erc20, deploy_minter, helper_sum_balance,
    helper_check_vintage_balances, helper_get_token_ids, deploy_vault, equals_with_error
};

fn get_values(token_ids: Span<u256>, cc_to_mint: u256) -> Array<u256> {
    let mut values: Array<u256> = Default::default();
    let mut index = 0;

    loop {
        if index >= token_ids.len() {
            break;
        };
        values.append(cc_to_mint);
        index += 1;
    };

    values
}

#[test]
fn test_batch_getter() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let alice: ContractAddress = contract_address_const::<'ALICE'>();
    let bob: ContractAddress = contract_address_const::<'BOB'>();
    let john: ContractAddress = contract_address_const::<'JOHN'>();

    let project_address = default_setup_and_deploy();
    let erc20_address = deploy_erc20();
    let vault_address = deploy_vault();
    let minter_address = deploy_minter(project_address, erc20_address);

    let vintages = IVintageDispatcher { contract_address: project_address };
    let vault_dispatcher = IVaultDispatcher { contract_address: vault_address };

    start_cheat_caller_address(project_address, owner_address);
    let project = IProjectDispatcher { contract_address: project_address };
    project.grant_minter_role(minter_address);
    stop_cheat_caller_address(project_address);
    start_cheat_caller_address(project_address, minter_address);

    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint_alice = initial_total_supply / 5; // 5% of the total supply
    let cc_to_mint_bob = initial_total_supply / 10; // 10% of the total supply
    let cc_to_mint_john = initial_total_supply / 15; // 15% of the total supply

    let token_ids = helper_get_token_ids(project_address);
    let values_alice = get_values(token_ids, cc_to_mint_alice);
    let values_bob = get_values(token_ids, cc_to_mint_bob);
    let values_john = get_values(token_ids, cc_to_mint_john);

    project.batch_mint(alice, token_ids, values_alice.span());
    project.batch_mint(bob, token_ids, values_bob.span());
    project.batch_mint(john, token_ids, values_john.span());

    let total_cc_balance_alice = helper_sum_balance(project_address, alice);
    assert(equals_with_error(total_cc_balance_alice, cc_to_mint_alice, 10), 'Error of balance');

    let total_cc_balance_bob = helper_sum_balance(project_address, bob);
    assert(equals_with_error(total_cc_balance_bob, cc_to_mint_bob, 10), 'Error of balance');

    let total_cc_balance_john = helper_sum_balance(project_address, john);
    assert(equals_with_error(total_cc_balance_john, cc_to_mint_john, 10), 'Error of balance');

    helper_check_vintage_balances(project_address, alice, cc_to_mint_alice);
    helper_check_vintage_balances(project_address, bob, cc_to_mint_bob);
    helper_check_vintage_balances(project_address, john, cc_to_mint_john);

    let res = vault_dispatcher.batch_getter(project_address, array![alice, bob, john]);

    assert(res.len() == token_ids.len() * 3, 'Wrong length');

    assert(*res.at(0).owner == alice, 'wrong owner');
    assert(*res.at(token_ids.len()).owner == bob, 'wrong owner');
    assert(*res.at(token_ids.len() * 2).owner == john, 'wrong owner');

    assert(*res.at(0).balance == project.balance_of(alice, 1), 'wrong balance');
    assert(*res.at(0).year == vintages.get_carbon_vintage(1).year, 'wrong year');
    assert(*res.at(0).status == vintages.get_carbon_vintage(1).status, 'wrong status');
}

#[test]
fn test_get_all_user_carbon_info() {
    let owner_address: ContractAddress = contract_address_const::<'OWNER'>();
    let alice: ContractAddress = contract_address_const::<'ALICE'>();

    let project_address = default_setup_and_deploy();
    let erc20_address = deploy_erc20();
    let vault_address = deploy_vault();
    let minter_address = deploy_minter(project_address, erc20_address);

    let vintages = IVintageDispatcher { contract_address: project_address };
    let vault_dispatcher = IVaultDispatcher { contract_address: vault_address };

    start_cheat_caller_address(project_address, owner_address);
    let project = IProjectDispatcher { contract_address: project_address };
    project.grant_minter_role(minter_address);
    stop_cheat_caller_address(project_address);
    start_cheat_caller_address(project_address, minter_address);

    let initial_total_supply = vintages.get_initial_project_cc_supply();
    let cc_to_mint_alice = initial_total_supply / 5; // 5% of the total supply

    let token_ids = helper_get_token_ids(project_address);
    let values_alice = get_values(token_ids, cc_to_mint_alice);

    project.batch_mint(alice, token_ids, values_alice.span());

    let total_cc_balance_alice = helper_sum_balance(project_address, alice);
    assert(equals_with_error(total_cc_balance_alice, cc_to_mint_alice, 10), 'Error of balance');

    helper_check_vintage_balances(project_address, alice, cc_to_mint_alice);

    let project_addresses = array![project_address];
    let res = vault_dispatcher.get_all_user_carbon_info(alice, project_addresses);
    let project = *res.at(0);

    assert(res.len() == 1, 'Wrong length');
    assert(project.project == project_address, 'wrong project');
    assert(project.vintage_info.len() == token_ids.len(), 'wrong Vintage length');
}
