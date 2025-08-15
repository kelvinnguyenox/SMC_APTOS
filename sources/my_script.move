// script {
//     use std::vector; 
//     use std::signer;
//     use aptos_framework::aptos_account;
//     use aptos_framework::aptos_coin;
//     use aptos_framework::coin;
//     use aptos_framework::object::{Self, Object, ObjectCore, ExtendRef, ConstructorRef};
    
//     use std::debug; 
    
//     use thalaswap_v2::pool::{Self, Pool}; 
//     use thalaswap_v2::coin_wrapper::{Self, Notacoin};
    
//     const THALA_POOL_USDC_USDT: address = @0xc3c4cbb3efcd3ec1b6679dc0ed45851486920dba0e86e612e80a79041a6cf1a3;
    
//     fun main(src: &signer, dest: address, desired_balance: u64) {
//         // let src_addr = signer::address_of(src);

//         // aptos_account::transfer(src, dest, desired_balance);
//         let amount = 100000; 

//         let amounts = vector::empty<u64>();
//             vector::push_back(&mut amounts, 0);
//             vector::push_back(&mut amounts, amount);
//             vector::push_back(&mut amounts, 0);
//             vector::push_back(&mut amounts, amount);

//         let pool_obj = object::address_to_object<thalaswap_v2::pool::Pool>(THALA_POOL_USDC_USDT);
//         let assets = thalaswap_v2::pool::pool_assets_metadata(pool_obj);
//         let preview = thalaswap_v2::pool::preview_add_liquidity_stable(pool_obj, assets, amounts);
//         debug::print(&preview);        
//         // let (lp_amount, _) = pool::add_liquidity_preview_info(preview);
//     }
// }

// // 0x5f3c0d4a44917f491ea4967718766b2671b00dca4e3c24bf62881d32a2512ea7


// //  aptos move run-script --script-path sources/my_script.move --args address:fc3ce8487b26cbe85e7b0b4f5bc093e3669042632b1b9ee49aa46341f6415e02 --args u64:5