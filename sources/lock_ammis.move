module aptos_tutorial::lock_ammis {
    use std::option::{Self, Option};
    use std::signer; 
    use std::vector;
    use std::error; 
    use std::string::{Self, String};
    use aptos_std::table::{Self, Table};
    use std::debug;

    use aptos_framework::timestamp::now_seconds;
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object, ObjectCore, ExtendRef};
    use aptos_framework::primary_fungible_store;

    use amnis::router;

    // Upgrade contract Nguyen Xuan Quy 1.0.0 version 
    
    // List of error codes
    const E_ALREADY_INITIALIZED: u64 = 1; 
    const E_NOT_INITIALIZED: u64 = 2;
    const E_NOT_ENOUGH_LOCKED: u64 = 2;

    #[event]
    struct DepositEvent has drop, store {
        sender: address, 
        amount: u64, 
        timestamp: u64,
    }

    #[event]
    struct WithdrawEvent has drop, store {
        sender: address, 
        amount: u64, 
        timestamp: u64,
    }

    struct Config has key {
        total_locked: u64, 
        total_unlocked: u64,
        min_lock_duration: u64, // in seconds
        max_lock_duration: u64, // in seconds
        lock_fee: u64, // in micro-APT
        unlock_fee: u64, // in micro-APT
    } 

      // -- Structs
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct LockAccount has key {
        total_deposit: u64, 
        current_locked: u64,
        total_withdrawn: u64,
        extend_ref: ExtendRef, 
        test_only: bool, // for testing purposes
    }

        // -- init
    fun init_module(sender: &signer) {
        let addr = signer::address_of(sender);
        assert!(
            !exists<Config>(addr),
            error::already_exists(E_ALREADY_INITIALIZED)
        );

        move_to(
            sender,
            Config {
                total_locked: 0, 
                total_unlocked: 0,
                min_lock_duration: 0, // in seconds
                max_lock_duration: 0, // in seconds
                lock_fee: 0, // in micro-APT
                unlock_fee: 0, // in micro-APT
            }
        );
    }

    public entry fun deposit(
        sender: &signer, 
        amount: u64, 
        lock_duration: u64
    ) acquires Config, LockAccount {
        let addr = signer::address_of(sender);
        assert!(exists<Config>(@aptos_tutorial), error::not_found(E_NOT_INITIALIZED));
        let config = borrow_global_mut<Config>(@aptos_tutorial);
        
        let lock_account = get_or_create_lock_account(sender);
        let lock_signer = &object::generate_signer_for_extending(&lock_account.extend_ref);

        lock_account.total_deposit += amount;
        lock_account.current_locked += amount;
        config.total_locked += amount;

        // aptos_account::transfer(sender, signer::address_of(lock_signer), amount); 
        
        router::deposit_and_stake_entry(sender, amount, signer::address_of(lock_signer));

        event::emit(
            DepositEvent {
                sender: addr,
                amount,
                timestamp: now_seconds(),
            }
        );
    }


    public entry fun withdraw(sender: &signer, amount: u64) acquires Config, LockAccount {
        let addr = signer::address_of(sender);
        assert!(exists<Config>(@aptos_tutorial), error::not_found(E_NOT_INITIALIZED));
        let config = borrow_global_mut<Config>(@aptos_tutorial);
        
        let lock_account = get_or_create_lock_account(sender);
        let lock_signer = &object::generate_signer_for_extending(&lock_account.extend_ref);

        assert!(lock_account.current_locked >= amount, error::invalid_argument(E_NOT_ENOUGH_LOCKED));

        lock_account.current_locked -= amount;
        lock_account.total_withdrawn += amount;

        config.total_unlocked += amount;

        // aptos_account::transfer(lock_signer, addr, amount); 
        
        router::unstake_entry(lock_signer, amount, addr);

        event::emit(
            WithdrawEvent {
                sender: addr,
                amount,
                timestamp: now_seconds(),
            }
        );

    }

    inline fun get_or_create_lock_account(sender: &signer): &mut LockAccount acquires LockAccount {
        let addr = signer::address_of(sender);
        if (!exists<LockAccount>(addr)) {
            let constructor_ref = object::create_object(addr);
            let extend_ref = object::generate_extend_ref(&constructor_ref);
            let obj_signer = &object::generate_signer_for_extending(&extend_ref);
            // let obj_signer = &object::generate_signer(&constructor_ref);
              // Creates the object
            // move_to(
            //     sender,
            //     LockAccount {
            //         total_deposit: 0, 
            //         current_locked: 0,
            //         total_withdrawn: 0,
            //         extend_ref,
            //     }
            // );
        }; 

        borrow_global_mut<LockAccount>(addr)
    }

    #[test_only]
    public fun init_module_for_test(sender: &signer) {
        let addr = signer::address_of(sender);
        assert!(
            !exists<Config>(addr),
            error::already_exists(E_ALREADY_INITIALIZED)
        );

        move_to(
            sender,
            Config {
                total_locked: 0, 
                total_unlocked: 0,
                min_lock_duration: 0, // in seconds
                max_lock_duration: 0, // in seconds
                lock_fee: 0, // in micro-APT
                unlock_fee: 0, // in micro-APT
            }
        );
    }
}   