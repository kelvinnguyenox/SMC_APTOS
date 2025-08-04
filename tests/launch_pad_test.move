// #[test_only]
// module aptos_tutorial::launch_pad_test {
//     use std::option::{Self, Option};
//     use std::string::{Self, String};
//     use std::signer;
//     use std::vector;
//     use std::debug; 

//     use aptos_tutorial::launch_pad; 
//     use aptos_framework::aptos_coin::{Self, AptosCoin}; 
//     use aptos_framework::primary_fungible_store;
//     use aptos_framework::coin;

//     public fun set_up_for_test(sender: &signer) {
//         launch_pad::init_module_for_test(sender);
//     }

//     public fun mint_fa(deployer: &signer) {
//         launch_pad::create_fa(
//             deployer,
//             option::some(1000),
//             string::utf8(b"FA2"),
//             string::utf8(b"FA2"),
//             3,
//             string::utf8(b"icon_url"),
//             string::utf8(b"project_url"),
//             option::some(1),
//             option::none(),
//             option::some(500)
//         );
//     }

//     #[test(deployer = @aptos_tutorial, user1 = @0x2)]
//     fun test_create_fa(deployer: &signer, user1: &signer) {
//         set_up_for_test(deployer);
//         launch_pad::create_fa(
//             deployer,
//             option::some(1000),
//             string::utf8(b"FA2"),
//             string::utf8(b"FA2"),
//             3,
//             string::utf8(b"icon_url"),
//             string::utf8(b"project_url"),
//             option::some(1),
//             option::none(),
//             option::some(500)
//         );
//     }

//     #[test(deployer = @aptos_tutorial, user1 = @0x2)]
//     fun test_mint_fa(deployer: &signer, user1: &signer) {
//         set_up_for_test(deployer);
//         mint_fa(deployer);
//         let registry = launch_pad::get_registry_fa_object();
//         let fa_1 = *vector::borrow(&registry, vector::length(&registry) - 1);

//         let pre_deployer_aptos_balance  = coin::balance<AptosCoin>(signer::address_of(user1));
//         debug::print(&pre_deployer_aptos_balance);

//         primary_fungible_store::deposit(signer::address_of(user1), aptos_coin::mint_apt_fa_for_test(200));
        
//         launch_pad::mint_fa(user1, fa_1, 100);
        
//         let pos_deployer_aptos_balance  = coin::balance<AptosCoin>(signer::address_of(user1));
//         let pos_deployer_real_aptos_balance  = coin::balance<AptosCoin>(signer::address_of(user1));

//         debug::print(&pos_deployer_aptos_balance);
//         debug::print(&pos_deployer_real_aptos_balance);
//     }
// }