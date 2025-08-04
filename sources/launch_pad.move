// module aptos_tutorial::launch_pad {
//     use std::option::{Self, Option};
//     use std::signer; 
//     use std::string::{Self, String};
//     use std::vector;
//     use aptos_std::table::{Self, Table};

//     use aptos_framework::aptos_account;
//     use aptos_framework::event;
//     use aptos_framework::fungible_asset::{Self, Metadata};
//     use aptos_framework::object::{Self, Object, ObjectCore};
//     use aptos_framework::primary_fungible_store;

//     /// Only admin can update creator
//     const EONLY_ADMIN_CAN_UPDATE_CREATOR: u64 = 1;
//     /// Only admin can set pending admin
//     const EONLY_ADMIN_CAN_SET_PENDING_ADMIN: u64 = 2;
//     /// Sender is not pending admin
//     const ENOT_PENDING_ADMIN: u64 = 3;
//     /// Only admin can update mint fee collector
//     const EONLY_ADMIN_CAN_UPDATE_MINT_FEE_COLLECTOR: u64 = 4;
//     /// No mint limit
//     const ENO_MINT_LIMIT: u64 = 5;
//     /// Mint limit reached
//     const EMINT_LIMIT_REACHED: u64 = 6;

//     /// Default to mint 0 amount to creator when creating FA
//     const DEFAULT_PRE_MINT_AMOUNT: u64 = 0;
//     /// Default mint fee per smallest unit of FA denominated in oapt (smallest unit of APT, i.e. 1e-8 APT)
//     const DEFAULT_mint_fee_per_smallest_unit_of_fa: u64 = 0;

//     #[event]
//     struct CreateFAEvent has store, drop {
//         creator_addr: address,
//         fa_owner_obj: Object<FAOwnerObjConfig>,
//         fa_obj: Object<Metadata>,
//         max_supply: Option<u128>,
//         name: String,
//         symbol: String,
//         decimals: u8,
//         icon_uri: String,
//         project_uri: String,
//         mint_fee_per_smallest_unit_of_fa: u64,
//         pre_mint_amount: u64,
//         mint_limit_per_addr: Option<u64>,
//     }

//     #[event]
//     struct MintFAEvent has store, drop {
//         fa_obj: Object<Metadata>,
//         amount: u64,
//         recipient_addr: address,
//         total_mint_fee: u64,
//     }

//     /// Unique per FA
//     /// We need this object to own the FA object instead of contract directly owns the FA object
//     /// This helps us avoid address collision when we create multiple FAs with same name
//     struct FAOwnerObjConfig has key {
//         // Only thing it stores is the link to FA object
//         fa_obj: Object<Metadata>
//     }

//     /// Unique per FA
//     struct FAController has key {
//         mint_ref: fungible_asset::MintRef,
//         burn_ref: fungible_asset::BurnRef,
//         transfer_ref: fungible_asset::TransferRef,
//     }

//     /// Unique per FA
//     struct MintLimit has store {
//         limit: u64,
//         mint_tracker: Table<address, u64>,
//     }

//     /// Unique per FA
//     struct FAConfig has key {
//         // Mint fee per FA denominated in oapt (smallest unit of APT, i.e. 1e-8 APT)
//         mint_fee_per_smallest_unit_of_fa: u64,
//         mint_limit: Option<MintLimit>,
//         fa_owner_obj: Object<FAOwnerObjConfig>,
//     }

//     /// Global per contract
//     struct Registry has key {
//         fa_objects: vector<Object<Metadata>>,
//     }

//     /// Global per contract
//     struct Config has key {
//         // admin can set pending admin, accept admin, update mint fee collector
//         admin_addr: address,
//         pending_admin_addr: Option<address>,
//         mint_fee_collector_addr: address,
//     }

//     // If you deploy the module under an object, sender is the object's signer
//     /// If you deploy the moduelr under your own account, sender is your account's signer
//     fun init_module(sender: &signer) {
//         move_to(sender, Registry {
//             fa_objects: vector::empty()
//         });
//         move_to(sender, Config {
//             admin_addr: signer::address_of(sender),
//             pending_admin_addr: option::none(),
//             mint_fee_collector_addr: signer::address_of(sender),
//         });
//     }

//     public entry fun set_pending_admin(sender: &signer, pending_admin_addr: address) acquires Config{
//         let sender_addr = signer::address_of(sender); 
//         let config = borrow_global_mut<Config>(@aptos_tutorial);
//         assert!(signer::address_of(sender) == config.admin_addr, EONLY_ADMIN_CAN_SET_PENDING_ADMIN); 
//         config.pending_admin_addr = option::some(pending_admin_addr);
//     }

//     public entry fun accept_admin(sender: &signer) acquires Config {
//         let sender_addr = signer::address_of(sender); 
//         let config = borrow_global_mut<Config>(@aptos_tutorial);
//         assert!(config.pending_admin_addr == option::some(sender_addr), ENOT_PENDING_ADMIN);
//         config.admin_addr = sender_addr; 
//         config.pending_admin_addr = option::none();
//     }

//     public entry fun update_mint_fee_collector_address(sender: &signer, new_mint_fee_collector_addr: address) acquires Config {
//         let sender_addr = signer::address_of(sender); 
//         let config = borrow_global_mut<Config>(@aptos_tutorial); 
//         assert!(sender_addr == config.admin_addr, EONLY_ADMIN_CAN_UPDATE_MINT_FEE_COLLECTOR);
//         config.mint_fee_collector_addr = new_mint_fee_collector_addr;

//     }

//     public entry fun create_fa(    
//         sender: &signer,
//         max_supply: Option<u128>,
//         name: String,
//         symbol: String,
//         // Number of decimal places, i.e. APT has 8 decimal places, so decimals = 8, 1 APT = 1e-8 oapt
//         decimals: u8,
//         icon_uri: String,
//         project_uri: String,
//         // Mint fee per smallest unit of FA denominated in oapt (smallest unit of APT, i.e. 1e-8 APT)
//         mint_fee_per_smallest_unit_of_fa: Option<u64>,
//         // Amount in smallest unit of FA
//         pre_mint_amount: Option<u64>,
//         // Limit of minting per address in smallest unit of FA
//         mint_limit_per_addr: Option<u64>
//         ) acquires Registry, FAController {
//         let sender_addr = signer::address_of(sender); 
//         let fa_owner_obj_constructor_ref = &object::create_object(@aptos_tutorial);
//         let fa_owner_obj_signer = &object::generate_signer(fa_owner_obj_constructor_ref);
        
//         let fa_obj_constructor_ref = &object::create_named_object(
//             fa_owner_obj_signer,
//             *string::bytes(&name),
//         );
//         let fa_obj_signer = &object::generate_signer(fa_obj_constructor_ref);

//         primary_fungible_store::create_primary_store_enabled_fungible_asset(
//             fa_obj_constructor_ref,
//             max_supply,
//             name,
//             symbol,
//             decimals,
//             icon_uri,
//             project_uri
//         );

//         let fa_obj = object::object_from_constructor_ref(fa_obj_constructor_ref);
//         move_to(fa_owner_obj_signer, FAOwnerObjConfig {
//             fa_obj,
//         });

//         let fa_owner_obj = object::object_from_constructor_ref(fa_owner_obj_constructor_ref);
//          let mint_ref = fungible_asset::generate_mint_ref(fa_obj_constructor_ref);
//         let burn_ref = fungible_asset::generate_burn_ref(fa_obj_constructor_ref);
//         let transfer_ref = fungible_asset::generate_transfer_ref(fa_obj_constructor_ref);
        
//         move_to(fa_obj_signer, FAController {
//             mint_ref,
//             burn_ref,
//             transfer_ref,
//         });

//         move_to(fa_obj_signer, FAConfig {
//             mint_fee_per_smallest_unit_of_fa: *option::borrow_with_default(&mint_fee_per_smallest_unit_of_fa, &DEFAULT_mint_fee_per_smallest_unit_of_fa),
//             mint_limit: if (option::is_some(&mint_limit_per_addr)) {
//                 option::some(MintLimit {
//                     limit: *option::borrow(&mint_limit_per_addr),
//                     mint_tracker: table::new()
//                 })
//             } else {
//                 option::none()
//             },
//             fa_owner_obj,
//         });
        
//           let registry = borrow_global_mut<Registry>(@aptos_tutorial);
//         vector::push_back(&mut registry.fa_objects, fa_obj);

//         event::emit(CreateFAEvent {
//             creator_addr: sender_addr,
//             fa_owner_obj,
//             fa_obj,
//             max_supply,
//             name,
//             symbol,
//             decimals,
//             icon_uri,
//             project_uri,
//             mint_fee_per_smallest_unit_of_fa: *option::borrow_with_default(&mint_fee_per_smallest_unit_of_fa, &DEFAULT_mint_fee_per_smallest_unit_of_fa),
//             pre_mint_amount: *option::borrow_with_default(&pre_mint_amount, &DEFAULT_PRE_MINT_AMOUNT),
//             mint_limit_per_addr,
//         });

//         if (*option::borrow_with_default(&pre_mint_amount, &DEFAULT_PRE_MINT_AMOUNT) > 0) {
//             let amount = *option::borrow(&pre_mint_amount);
//             mint_fa_internal(sender, fa_obj, amount, 0);
//         }
//     }

//     public entry fun mint_fa(sender: &signer, fa_obj: Object<Metadata>, amount: u64) acquires FAConfig, FAController, Config {
//         let sender_addr = signer::address_of(sender); 
//         let fa_config = borrow_global<FAConfig>(object::object_address(&fa_obj));
//         // let mint_limit = &fa_config.mint_limit;
//         // let mint_tracker = mint_limmit::limit; 
    
//         mint_fa_internal(sender, fa_obj, amount, 0);
//         pay_for_mint(sender, amount);
//     }


//     /// ACtual implementation of minting FA
//     fun mint_fa_internal(
//         sender: &signer,
//         fa_obj: Object<Metadata>,
//         amount: u64,
//         total_mint_fee: u64,
//     ) acquires FAController {
//         let sender_addr = signer::address_of(sender);
//         let fa_obj_addr = object::object_address(&fa_obj);

//         let fa_controller = borrow_global<FAController>(fa_obj_addr);
//         primary_fungible_store::mint(&fa_controller.mint_ref, sender_addr, amount);

//         event::emit(MintFAEvent {
//             fa_obj,
//             amount,
//             recipient_addr: sender_addr,
//             total_mint_fee,
//         });
//     }
    
//     fun pay_for_mint(sender: &signer, total_mint_fee: u64) acquires Config {
//         let config = borrow_global<Config>(@aptos_tutorial);
//         let mint_fee_collector_addr = config.mint_fee_collector_addr;
//         aptos_account::transfer(sender, config.mint_fee_collector_addr, total_mint_fee)
//     }

//     #[view]
//     public fun get_current_minted_amount(fa_obj: Object<Metadata>, sender: address): u64 acquires FAConfig {
//         let fa_obj_address = object::object_address(&fa_obj);
//         if(exists<FAConfig>(fa_obj_address) == false) {
//             return 0;
//         }; 

//         let fa_config = borrow_global<FAConfig>(fa_obj_address);

//         let mint_limit = option::borrow(&fa_config.mint_limit);
//         let mint_tracker = &mint_limit.mint_tracker;
//         *table::borrow_with_default(mint_tracker, sender, &0)
//     }

//     #[view]
//     public fun get_registry_fa_object(): vector<Object<Metadata>> acquires Registry {
//         let registry = borrow_global<Registry>(@aptos_tutorial);
//         registry.fa_objects
//     }

//     #[test_only]
//     public fun init_module_for_test(sender: &signer) {
//         init_module(sender);
//     }
// }   
