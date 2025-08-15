// module aptos_tutorial::staking_fa_test {
//     use std::signer;
//     use std::bcs;
//     use std::vector;
//     use std::debug;

//     use aptos_framework::account;
//     use aptos_framework::object::{Self, Object, ObjectCore, ExtendRef};
//     use aptos_framework::fungible_asset::{Self, Metadata, FungibleAsset};
//     use aptos_framework::primary_fungible_store;
//     use aptos_framework::timestamp::{Self};
//     use aptos_tutorial::test_helpers;
    
//     use aptos_tutorial::staking_fa;

//     fun setup(deployer: &signer, wallet1: &signer, wallet2: &signer): (Object<Metadata>) {
//         // setup clock
//         timestamp::set_time_has_started_for_testing(
//             &account::create_signer_for_test(@0x1)
//         );

//         // setup modules
//         staking_fa::init_module_for_test(deployer);

//         // setup acccounts
//         let deployer_addr = signer::address_of(deployer);
//         let wallet1_addr = signer::address_of(wallet1);
//         let wallet2_addr = signer::address_of(wallet2);
//         account::create_account_for_test(deployer_addr);
//         account::create_account_for_test(wallet1_addr);
//         account::create_account_for_test(wallet2_addr);

//         // setup asset
//         let (token, mint_ref, _) = test_helpers::create_fake_USDC(deployer);
//         let init_amount = 1_000_000_000; // 1000 USDC

//         // Mint fake token to wallet 1 
//         primary_fungible_store::mint(&mint_ref, wallet1_addr, init_amount);
//         // Mint fake token to wallet 2
//         primary_fungible_store::mint(&mint_ref, wallet2_addr, init_amount);
        
//         token
//     }

//     #[test(deployer = @aptos_tutorial, wallet1 = @0x111, wallet2 = @0x222)]
//     fun test_register_should_right(
//         deployer: &signer, wallet1: &signer, wallet2: &signer
//     ) {
//         let fake_usdc = setup(deployer, wallet1, wallet2);

//         let deposit_amount = 10000;

//         staking_fa::deposit_funds(wallet1, fake_usdc, deposit_amount); // 100 USDC

//         let deposit_amount = staking_fa::get_deposit_amount(signer::address_of(wallet1));

//         debug::print(&deposit_amount);

//         staking_fa::with_draw(wallet1, fake_usdc, 1000); // 100 USDC

//         deposit_amount = staking_fa::get_deposit_amount(signer::address_of(wallet1));

//         debug::print(&deposit_amount);
//     }
// }