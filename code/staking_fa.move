// module aptos_tutorial::staking_fa {
//     use std::signer; 
//     use std::string::{Self, String};
//     use std::option::{Self, Option};
//     use std::vector;
//     use std::debug; 

//     use aptos_framework::primary_fungible_store;
//     use aptos_framework::object::{Self, Object};
//     use aptos_framework::aptos_account;
//     use aptos_framework::event;
//     use aptos_framework::fungible_asset::{Self, Metadata};

//     const OBJECT_NAME: vector<u8> = b"STAKING_FA_CONFIG";
//     const OBJECT_NAME_RECEIVER_FA: vector<u8> = b"RECEIVER_FA";
    
//     struct Config has key {
//         treasury: Option<address>, 
//         fund_to: address, 
//         epoch_rate: u64, 
//         total_staked: u64,
//         total_rewards: u64,
//         total_withdraw: u64,
//         total_claim_rewards: u64
//     }

//     struct Stake has key {
//         staker: address,
//         amount: u64,
//         rewards: u64,
//         last_epoch: u64
//     }

//     fun init_module(sender: &signer) {
//         let constructor_ref_fund_to = &object::create_named_object(sender, OBJECT_NAME_RECEIVER_FA);
//         let fund_to_signer = &object::generate_signer(constructor_ref_fund_to);

//         let config = Config {
//             treasury: option::none(),
//             fund_to: signer::address_of(fund_to_signer),
//             epoch_rate: 0,
//             total_staked: 0,
//             total_rewards: 0,
//             total_withdraw: 0,
//             total_claim_rewards: 0
//         };
//         let constructor_ref = &object::create_named_object(sender, OBJECT_NAME);
//         let config_signer = &object::generate_signer(constructor_ref);
        
//         move_to(config_signer, config);
//     }


//     public entry fun deposit_funds(sender: &signer, fa: Object<Metadata>, amount: u64) acquires Config {
//         let config_addr = get_config_add();
//         let config = borrow_global_mut<Config>(config_addr);

//         primary_fungible_store::transfer(sender, fa, config.fund_to, amount);
//     }

//     public entry fun withdraw_funds(sender: &signer, fa: Object<Metadata>, amount: u64) acquires Config {
//         let config_addr = get_config_add();

//         let config = borrow_global_mut<Config>(config_addr);
        
//         primary_fungible_store::transfer(sender, fa, signer::address_of(config_signer), amount);
//     }


//     fun get_config_add(): address acquires Config {
//          let constructor_ref = &object::create_named_object(sender, OBJECT_NAME);
//         let config_signer = &object::generate_signer(constructor_ref);
//         signer::address_of(config_signer)
//     }

//     #[view]
//     fun get_epoch_rate(): u64 acquires Config {
//         let config = borrow_global<Config>(@aptos_tutorial);
//         config.epoch_rate
//     }
// }