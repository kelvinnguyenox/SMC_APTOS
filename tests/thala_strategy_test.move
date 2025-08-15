// #[test_only]
// module aptos_tutorial::thala_strategy_test {
//     use std::option::{Self, Option};
//     use std::string::{Self, String};
//     use std::signer;
//     use std::vector;
//     use std::debug; 

//     use aptos_framework::account;
//     use aptos_framework::timestamp;
//     use aptos_framework::aptos_coin::{Self, AptosCoin}; 
//     use aptos_framework::object::{Self, Object};
//     use aptos_framework::primary_fungible_store;
//     use aptos_framework::coin;
//     use aptos_framework::fungible_asset::{
//         Self,
//         Metadata,
//         MintRef,
//     };

//     use aptos_tutorial::thala_strategy; 
//     use aptos_tutorial::test_helpers; 
    
//     const DEPOSIT_AMOUNT: u64 = 1000;
    
//     public fun set_up_for_test(sender: &signer, user1: &signer, user2: &signer): (Object<Metadata>, MintRef){
//         timestamp::set_time_has_started_for_testing(
//             &account::create_signer_for_test(@0x1)
//         );

//         thala_strategy::init_module_for_test(sender);
//         let (asset, mint_ref, _)  = test_helpers::create_fake_USDC(sender);

//         thala_strategy::upsert_supported_asset(
//             sender,
//             asset,
//             true
//         );

//         primary_fungible_store::mint(
//             &mint_ref,
//             signer::address_of(user1),
//             DEPOSIT_AMOUNT
//         );

//         primary_fungible_store::mint(
//             &mint_ref,
//             signer::address_of(user2),
//             DEPOSIT_AMOUNT
//         );
//         (asset, mint_ref)
//     }

//     public fun deal_fa(mint_ref: &MintRef, user: &signer, amount: u64) {
//         primary_fungible_store::mint(
//             mint_ref,
//             signer::address_of(user),
//             amount
//         );
//     }

//     #[test(deployer = @aptos_tutorial, user1 = @0x1, user2 = @0x2)]
//     fun test_deposit_should_right(deployer: &signer, user1: &signer, user2: &signer) {
//         let (asset_metadata, mint_ref ) = set_up_for_test(deployer, user1, user2);
//         let lp_metadata = thala_strategy::get_lp_metadata();
//         let usdc_bl = primary_fungible_store::balance(
//             signer::address_of(user1),
//             asset_metadata,
//         );
//         debug::print(&usdc_bl);

//         thala_strategy::deposit(
//             user1,
//             asset_metadata,
//             DEPOSIT_AMOUNT
//         );

//         // let lp_bl = primary_fungible_store::balance(
//         //     signer::address_of(user1),
//         //     lp_metadata,
//         // );
//         // debug::print(&lp_bl);

//         usdc_bl = primary_fungible_store::balance(
//             signer::address_of(user1),
//             asset_metadata,
//         );
//         debug::print(&usdc_bl);
//         thala_strategy::withdraw(
//             user1,
//             asset_metadata,
//             DEPOSIT_AMOUNT
//         );
//         // lp_bl = primary_fungible_store::balance(
//         //     signer::address_of(user1),
//         //     lp_metadata,
//         // );
//         // debug::print(&lp_bl);

//         usdc_bl = primary_fungible_store::balance(
//             signer::address_of(user1),
//             asset_metadata,
//         );
//         debug::print(&usdc_bl);
//     }
// }