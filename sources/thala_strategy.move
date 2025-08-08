module aptos_tutorial::thala_strategy {
    use std::signer; 
    use std::vector; 
    use std::error; 
    use std::option;
    use std::string;
    use aptos_framework::fungible_asset::{Self, Metadata, MintRef, BurnRef, TransferRef};
    use aptos_framework::object::{Self, Object, ObjectCore, ExtendRef, ConstructorRef};
    use aptos_framework::event;
    use aptos_framework::primary_fungible_store;    
    use aptos_framework::aptos_account;
    use aptos_framework::ordered_map::{Self, OrderedMap};
    use aptos_framework::timestamp::now_seconds;   

    const ADMIN_ROLE: u64 = 1; 
    const DELEGATE_ADMIN_ROLE: u64 = 2;
    const LOCK_ACCOUNT_SEED: vector<u8> = b"lock_account";

    #[event]
    struct DepositEvent has drop, store {
        sender: address,
        asset: Object<Metadata>,
        amount: u64,
        timestamp: u64,
    }

    #[event]
    struct WithdrawEvent has drop, store {
        sender: address, 
        asset: Object<Metadata>,
        amount: u64,
        timestamp: u64,
    }

    // -- Structs
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct LockAccount has key {
       assets: OrderedMap<address, Asset>, // address -> Asset
       extend_ref: ExtendRef,
    }

    struct Asset has key, store, drop{
        total_deposit: u64, 
        current_locked: u64,
        total_withdrawn: u64,
        lp_amount: u64, 
    }

    struct LpController has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
        extend_ref: ExtendRef,
    }

    struct Config has key {
        supported_assets: OrderedMap<address, bool>, // address -> is supported
        admins: OrderedMap<address, u64>, // address -> role 
        lock_duration: u64, // in seconds
    }
   

    struct ThalaPosition has key {

    }

    fun init_module(sender: &signer) {
        let sender_addr = signer::address_of(sender);
        let admin= if(object::is_object(sender_addr)) {
            object::root_owner(object::address_to_object<ObjectCore>(sender_addr))
        } else {
            sender_addr
        };

        let admins = ordered_map::new<address, u64>();
        ordered_map::upsert(&mut admins, admin, ADMIN_ROLE); 

        init_lp_token(sender);
        move_to(sender, Config {
            supported_assets: ordered_map::new<address, bool>(), 
            admins: admins,
            lock_duration: 60 * 60 * 24 * 30, 
        });
    } 

    public entry fun deposit(sender: &signer, asset: Object<Metadata>, amount: u64) acquires Config, LockAccount, LpController {
        is_supported_asset(asset); 
        let lock_account_obj = get_or_create_if_not_exists_lock_account(sender); 
        let lock_account_addr = object::object_address(&lock_account_obj);
        let lock_account = borrow_global_mut<LockAccount>(lock_account_addr);
        let asset_addr = object::object_address(&asset); 

        let mint_lp_amount = cal_lp_amount(amount);
        if(ordered_map::contains(&lock_account.assets, &asset_addr)) {
            let asset_stat = ordered_map::borrow_mut(&mut lock_account.assets, &asset_addr);
            asset_stat.total_deposit = asset_stat.total_deposit + amount;
            asset_stat.current_locked = asset_stat.current_locked + amount;

        } else {
            let new_asset = Asset {
                total_deposit: amount,
                current_locked: amount,
                total_withdrawn: 0,
                lp_amount: cal_lp_amount(amount),
            };
            ordered_map::upsert(&mut lock_account.assets, asset_addr, new_asset);
        };

        mint_lp(sender, mint_lp_amount);

        primary_fungible_store::transfer(
            sender,
            asset,
            lock_account_addr,
            amount
        );

        event::emit(
            DepositEvent {
                sender: signer::address_of(sender),
                asset: asset,
                amount: amount,
                timestamp: now_seconds(),
            }
        )
    }

    public entry fun withdraw(sender: &signer, asset: Object<Metadata>, amount: u64) acquires Config, LockAccount, LpController {
        is_supported_asset(asset); 
        let lock_account_obj = get_or_create_if_not_exists_lock_account(sender);
        let lock_account = borrow_global_mut<LockAccount>(object::object_address(&lock_account_obj));
        let asset_stat = ordered_map::borrow_mut(&mut lock_account.assets, &object::object_address(&asset));
        let lock_account_signer = &object::generate_signer_for_extending(&lock_account.extend_ref);
        
        asset_stat.total_deposit = asset_stat.total_deposit - amount;
        asset_stat.current_locked = asset_stat.current_locked - amount;
        asset_stat.total_withdrawn = asset_stat.total_withdrawn + amount;

        burn_lp(sender, cal_lp_amount(amount));

        primary_fungible_store::transfer(lock_account_signer, asset, signer::address_of(sender), amount);

        event::emit(
            WithdrawEvent {
                sender: signer::address_of(sender),
                asset: asset,
                amount: amount,
                timestamp: now_seconds(),
            }
        )
    }

    ////////////////////////////////////////////////////////////////
    /////////////////////// private functions /////////////////////
    //////////////////////////////////////////////////////////////
    fun init_lp_token(sender: &signer) {
        let constructor_ref = &object::create_sticky_object(@aptos_tutorial);
        let lp_address = object::address_from_constructor_ref(constructor_ref);
        
        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::some(100), // max supply
            string::utf8(b"HNQ"),
            string::utf8(b"HNQ"),
            9,
            string::utf8(b"http://example.com/icon"),
            string::utf8(b"http://example.com"),
        ); 


        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let extend_ref = object::generate_extend_ref(constructor_ref);

        move_to(sender, LpController {
            mint_ref,
            transfer_ref,
            burn_ref,
            extend_ref,
        })
    }

    fun is_supported_asset(asset_addr: Object<Metadata>): bool acquires Config {
        let config = borrow_global<Config>(@aptos_tutorial);

        ordered_map::contains(&config.supported_assets, &object::object_address(&asset_addr))
    }
    

    fun get_or_create_if_not_exists_lock_account(
        sender: &signer, 
    ): Object<LockAccount> {
        let sender_addr = signer::address_of(sender);
        let is_lock_account_exists = !exists<LockAccount>(sender_addr);
        if(!is_lock_account_exists) {
           let constructor_ref = &object::create_named_object(sender, LOCK_ACCOUNT_SEED);
            let extend_ref = object::generate_extend_ref(constructor_ref);

            move_to(sender, LockAccount {
                assets: ordered_map::new<address, Asset>(),
                extend_ref: extend_ref,
            });
        };
        
       object::address_to_object<LockAccount>(sender_addr)
    }

    fun cal_lp_amount(amount: u64): u64 {
        amount * 1000
    }

    fun mint_lp(sender: &signer, amount: u64) acquires LpController {
        let lp_controller = borrow_global<LpController>(@aptos_tutorial);
        primary_fungible_store::mint(
            &lp_controller.mint_ref,
            signer::address_of(sender),
            amount
        );
    }

    fun burn_lp(sender: &signer, amount: u64) acquires LpController {
        let lp_controller = borrow_global<LpController>(@aptos_tutorial);
        primary_fungible_store::burn(
            &lp_controller.burn_ref,
            signer::address_of(sender),
            amount
        );
    }
}