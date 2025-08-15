// module aptos_tutorial::thala_strategy {
//     use std::signer; 
//     use std::vector; 
//     use std::error; 
//     use std::option;
//     use std::string;
//     use aptos_framework::fungible_asset::{Self, Metadata, MintRef, BurnRef, TransferRef};
//     use aptos_framework::object::{Self, Object, ObjectCore, ExtendRef, ConstructorRef};
//     use aptos_framework::event;
//     use aptos_framework::primary_fungible_store;    
//     use aptos_framework::aptos_account;
//     use aptos_framework::ordered_map::{Self, OrderedMap};
//     use aptos_framework::timestamp::now_seconds;   

//     // Thala Strategy Module
//     use thalaswap_v2::pool::{Self, Pool}; 
//     use thalaswap_v2::coin_wrapper::{Self, Notacoin};

//     #[test_only]
//     use std::debug;

//     const ADMIN_ROLE: u64 = 1; 
//     const DELEGATE_ADMIN_ROLE: u64 = 2;
//     const LOCK_ACCOUNT_SEED: vector<u8> = b"lock_account";
//     const USDC: address = @usdc; 
//     const USDT: address = @usdt; 
//     const THALA_POOL_USDC_USDT: address = @0xc3c4cbb3efcd3ec1b6679dc0ed45851486920dba0e86e612e80a79041a6cf1a3;

//     const E_NOT_AUTHORIZED: u64 = 1;
//     const E_NOT_FOUND: u64 = 2; 

//     #[event]
//     struct DepositEvent has drop, store {
//         sender: address,
//         asset: Object<Metadata>,
//         amount: u64,
//         timestamp: u64,
//     }

//     #[event]
//     struct WithdrawEvent has drop, store {
//         sender: address, 
//         asset: Object<Metadata>,
//         amount: u64,
//         timestamp: u64,
//     }

//     // -- Structs
//     #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
//     struct LockAccount has key {
//        assets: OrderedMap<address, Asset>, // address -> Asset
//        thala_poisiton: ThalaPosition, // position in thala pool
//     }

//     struct ThalaPosition has key, store {
//         lp_amount: u64, // LP token amount in thala pool
//     }

//     struct Asset has key, store, drop{
//         total_deposit: u64, 
//         current_locked: u64,
//         total_withdrawn: u64,
//         lp_amount: u64, 
//     }

//     struct LockAccountController has key {
//         lock_account: Object<LockAccount>,
//         extend_ref: ExtendRef,
//     }

//     struct LpController has key {
//         mint_ref: MintRef,
//         transfer_ref: TransferRef,
//         burn_ref: BurnRef,
//         extend_ref: ExtendRef,
//     }

//     struct Config has key {
//         supported_assets: OrderedMap<address, bool>, // address -> is supported
//         admins: OrderedMap<address, u64>, // address -> role 
//         lp_metadata: Object<Metadata>, // LP token metadata
//         lock_duration: u64, // in seconds
//     }
   

//     fun init_module(sender: &signer) {
//         let sender_addr = signer::address_of(sender);
//         let admin= if(object::is_object(sender_addr)) {
//             object::root_owner(object::address_to_object<ObjectCore>(sender_addr))
//         } else {
//             sender_addr
//         };

//         let admins = ordered_map::new<address, u64>();
//         ordered_map::upsert(&mut admins, admin, ADMIN_ROLE); 

//         let lp_metadata = init_lp_token(sender);
//         move_to(sender, Config {
//             supported_assets: ordered_map::new<address, bool>(), 
//             admins: admins,
//             lp_metadata: lp_metadata,
//             lock_duration: 60 * 60 * 24 * 30, 
//         });
//     } 

//     public entry fun deposit_thala(sender: &signer, asset: Object<Metadata>, amount: u64) {
//         let asset_addr = object::object_address(&asset);
//         let pool_obj = object::address_to_object<Pool>(THALA_POOL_USDC_USDT);

//         let amounts = vector::empty<u64>();
//         if(asset_addr == USDC) {
//             vector::push_back(&mut amounts, 0);
//             vector::push_back(&mut amounts, amount);
//         } else if(asset_addr == USDT) {
//             vector::push_back(&mut amounts, 0);
//             vector::push_back(&mut amounts, amount);
//         } else {
//             error::not_found(E_NOT_FOUND);
//         };

//         let assets = pool::pool_assets_metadata(pool_obj);
//         let preview = pool::preview_add_liquidity_stable(pool_obj, assets, amounts);
//         let (lp_amount, _) = pool::add_liquidity_preview_info(preview);

//         coin_wrapper::add_liquidity_stable<Notacoin, Notacoin, Notacoin, Notacoin, Notacoin, Notacoin>(
//             sender,
//             object::address_to_object<Pool>(THALA_POOL_USDC_USDT),
//             amounts,
//             lp_amount
//         );
//     }

//     public entry fun deposit(sender: &signer, asset: Object<Metadata>, amount: u64) acquires Config, LockAccount, LpController, LockAccountController {
//         is_supported_asset(asset); 
//         if(!exists<LockAccountController>(signer::address_of(sender))) {
//             create_lock_account(sender)
//         };

//         let sender_addr = signer::address_of(sender);
//         let lock_account_controller = borrow_global_mut<LockAccountController>(sender_addr);
//         let lock_account_addr = object::object_address(&lock_account_controller.lock_account);
//         let lock_account = borrow_global_mut<LockAccount>(lock_account_addr);
//         let lock_account_signer = &object::generate_signer_for_extending(&lock_account_controller.extend_ref);
//         let asset_addr = object::object_address(&asset);
//         let pool_obj = object::address_to_object<Pool>(THALA_POOL_USDC_USDT);

//         let mint_lp_amount = cal_lp_amount(amount);
//         if(ordered_map::contains(&lock_account.assets, &asset_addr)) {
//             let asset_stat = ordered_map::borrow_mut(&mut lock_account.assets, &asset_addr);
//             asset_stat.total_deposit = asset_stat.total_deposit + amount;
//             asset_stat.current_locked = asset_stat.current_locked + amount;

//         } else {
//             let new_asset = Asset {
//                 total_deposit: amount,
//                 current_locked: amount,
//                 total_withdrawn: 0,
//                 lp_amount: cal_lp_amount(amount),
//             };
//             ordered_map::upsert(&mut lock_account.assets, asset_addr, new_asset);
//         };

//         mint_lp(sender, mint_lp_amount);

//         primary_fungible_store::transfer(
//             sender,
//             asset,
//             lock_account_addr,
//             amount
//         );

//         let amounts = vector::empty<u64>();
//         if(asset_addr == USDC) {
//             vector::push_back(&mut amounts, 0);
//             vector::push_back(&mut amounts, amount);
//         } else if(asset_addr == USDT) {
//             vector::push_back(&mut amounts, 0);
//             vector::push_back(&mut amounts, amount);
//         } else {
//             error::not_found(E_NOT_FOUND);
//         };

//         let assets = pool::pool_assets_metadata(pool_obj);
//         let preview = pool::preview_add_liquidity_stable(pool_obj, assets, amounts);
//         let (lp_amount, _) = pool::add_liquidity_preview_info(preview);

//         coin_wrapper::add_liquidity_stable<Notacoin, Notacoin, Notacoin, Notacoin, Notacoin, Notacoin>(
//             lock_account_signer,
//             object::address_to_object<Pool>(THALA_POOL_USDC_USDT),
//             amounts,
//             lp_amount
//         );
        
//        lock_account.thala_poisiton.lp_amount = lock_account.thala_poisiton.lp_amount + lp_amount;

//         event::emit(
//             DepositEvent {
//                 sender: signer::address_of(sender),
//                 asset: asset,
//                 amount: amount,
//                 timestamp: now_seconds(),
//             }
//         )

//     }

//     public entry fun withdraw(sender: &signer, asset: Object<Metadata>, amount: u64) acquires Config, LockAccount, LpController, LockAccountController {
//         is_supported_asset(asset); 
//         if(!exists<LockAccountController>(signer::address_of(sender))) {
//             error::not_found(E_NOT_FOUND);
//         };

//         let sender_addr = signer::address_of(sender);
//         let lock_account_controller = borrow_global_mut<LockAccountController>(sender_addr);
//         let lock_account_addr = object::object_address(&lock_account_controller.lock_account);
//         let lock_account = borrow_global_mut<LockAccount>(lock_account_addr);
//         let lock_account_signer = &object::generate_signer_for_extending(&lock_account_controller.extend_ref);
//         let asset_stat = ordered_map::borrow_mut(&mut lock_account.assets, &object::object_address(&asset));
//         let pool_obj = object::address_to_object<Pool>(THALA_POOL_USDC_USDT);
//         let thala_lp_metadata = pool::pool_lp_token_metadata(pool_obj);

//         asset_stat.total_deposit = asset_stat.total_deposit - amount;
//         asset_stat.current_locked = asset_stat.current_locked - amount;
//         asset_stat.total_withdrawn = asset_stat.total_withdrawn + amount;

//     //   pool::remove_liquidity_entry(lock_account_signer, pool_obj, thala_lp_metadata, ) ; 
//         burn_lp(sender, cal_lp_amount(amount));

//         primary_fungible_store::transfer(lock_account_signer, asset, signer::address_of(sender), amount);

//         event::emit(
//             WithdrawEvent {
//                 sender: signer::address_of(sender),
//                 asset: asset,
//                 amount: amount,
//                 timestamp: now_seconds(),
//             }
//         )
//     }


//     public entry fun upsert_supported_asset(
//         sender: &signer, 
//         asset: Object<Metadata>, 
//         is_supported: bool
//     ) acquires Config {
//         let config = borrow_global_mut<Config>(@aptos_tutorial);
//         let sender_addr = signer::address_of(sender);
         
//         if(!ordered_map::contains(&config.admins, &sender_addr)) {
//             error::not_found(E_NOT_FOUND);
//         };
        
//         let sender = *ordered_map::borrow(&config.admins, &sender_addr);
//         if(sender != ADMIN_ROLE && sender != DELEGATE_ADMIN_ROLE) {
//             error::permission_denied(E_NOT_AUTHORIZED);
//         };

//         ordered_map::upsert(&mut config.supported_assets, object::object_address(&asset), is_supported);
//     }   

//     #[view]
//     public fun get_lp_metadata(): Object<Metadata> acquires Config {
//         let config = borrow_global<Config>(@aptos_tutorial);
//         config.lp_metadata
//     }
//     ////////////////////////////////////////////////////////////////
//     /////////////////////// private functions /////////////////////
//     //////////////////////////////////////////////////////////////
//     fun init_lp_token(sender: &signer): Object<Metadata> {
//         let constructor_ref = &object::create_sticky_object(@aptos_tutorial);
        
//         primary_fungible_store::create_primary_store_enabled_fungible_asset(
//             constructor_ref,
//             option::none(), // max supply
//             string::utf8(b"HNQ"),
//             string::utf8(b"HNQ"),
//             9,
//             string::utf8(b"http://example.com/icon"),
//             string::utf8(b"http://example.com"),
//         ); 


//         let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
//         let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
//         let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
//         let extend_ref = object::generate_extend_ref(constructor_ref);

//         move_to(sender, LpController {
//             mint_ref,
//             transfer_ref,
//             burn_ref,
//             extend_ref,
//         }); 

//         object::address_to_object<Metadata>(object::address_from_constructor_ref(constructor_ref))
//     }

//     fun is_supported_asset(asset_addr: Object<Metadata>): bool acquires Config {
//         let config = borrow_global<Config>(@aptos_tutorial);

//         ordered_map::contains(&config.supported_assets, &object::object_address(&asset_addr))
//     }
    

//     fun create_lock_account(
//         sender: &signer, 
//     ) {
//         let sender_addr = signer::address_of(sender);

//         let constructor_ref = &object::create_named_object(sender, LOCK_ACCOUNT_SEED);
//         // Retrieves a signer for the object
//         let object_signer = object::generate_signer(constructor_ref);
        
//         let extend_ref = object::generate_extend_ref(constructor_ref);

//         move_to(&object_signer, LockAccount {
//                 assets: ordered_map::new<address, Asset>(),
//                 thala_poisiton: ThalaPosition {
//                     lp_amount: 0,
//                 },
//         });

//         move_to(sender, LockAccountController {
//             lock_account: object::address_to_object<LockAccount>(object::address_from_constructor_ref(constructor_ref)),
//             extend_ref,
//         });
//     }

//     fun cal_lp_amount(amount: u64): u64 {
//         amount * 1000
//     }

//     fun mint_lp(sender: &signer, amount: u64) acquires LpController {
//         let lp_controller = borrow_global<LpController>(@aptos_tutorial);
//         primary_fungible_store::mint(
//             &lp_controller.mint_ref,
//             signer::address_of(sender),
//             amount
//         );
//     }

//     fun burn_lp(sender: &signer, amount: u64) acquires LpController {
//         let lp_controller = borrow_global<LpController>(@aptos_tutorial);
//         primary_fungible_store::burn(
//             &lp_controller.burn_ref,
//             signer::address_of(sender),
//             amount
//         );
//     }

//     #[test_only]
//     public fun init_module_for_test(sender: &signer) {
//         init_module(sender);
//     }
// }