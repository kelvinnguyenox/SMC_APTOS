module aptos_tutorial::staking_fa {
    use std::signer; 
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use std::vector;
    #[test_only]
    use std::debug; 

    use aptos_framework::primary_fungible_store;
    use aptos_framework::object::{Self, Object, ExtendRef};
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::{Self, Metadata};

    const STAKING_FA_CONFIG: vector<u8> = b"STAKING_FA_CONFIG";
    
    // Upgrade contract
      // -- Structs
    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct StakeAccount has key {
        stake_account: StakeAsset, 
        extend_ref: ExtendRef
    }

    struct Config has key {
        treasury: Option<address>, 
        epoch_rate: u64, 
        total_staked: u64,
        total_rewards: u64,
        total_withdraw: u64,
        total_claim_rewards: u64
    }

    struct StakeAsset has store {
        staker: address,
        amount: u64,
        rewards: u64,
        last_epoch: u64, 
    }


    fun init_module(sender: &signer) {
        let config = Config {
            treasury: option::none(),
            epoch_rate: 0,
            total_staked: 0,
            total_rewards: 0,
            total_withdraw: 0,
            total_claim_rewards: 0
        };
        let constructor_ref = &object::create_named_object(sender, STAKING_FA_CONFIG);
        let config_signer = &object::generate_signer(constructor_ref);
        
        move_to(config_signer, config);
    }


    public entry fun deposit_funds(sender: &signer, fa: Object<Metadata>, amount: u64) acquires StakeAccount {
        let caller_address = signer::address_of(sender);
        let account_signer_address; 

        if(exists<StakeAccount>(caller_address)) {
            let stake_obj = borrow_global_mut<StakeAccount>(caller_address);
            // how to get the signer address from the extend ref
            account_signer_address = signer::address_of(&object::generate_signer_for_extending(&stake_obj.extend_ref));
            // update the amount staked
            stake_obj.stake_account.amount = stake_obj.stake_account.amount + amount;
        } else {
            // creates the object
            let constructor_ref = object::create_object(caller_address);
            // creates an extend ref, and moves it to the object
            let extend_ref = object::generate_extend_ref(&constructor_ref);
            // creates the signer for the object
            // let object_signer = &object::generate_signer(&constructor_ref);
            let object_signer = &object::generate_signer_for_extending(&extend_ref);
            /// get the address of the signer
            account_signer_address = signer::address_of(object_signer);

            let stake_asset = StakeAsset {
                staker: caller_address,
                amount,
                rewards: 0,
                last_epoch: 0,
            };
            let stake_account = StakeAccount {
                stake_account: stake_asset,
                extend_ref
            };
            move_to(sender, stake_account);
        };
        primary_fungible_store::transfer(sender, fa, account_signer_address , amount);
        
    }

    public entry fun with_draw(sender: &signer, fa: Object<Metadata>, amount: u64) acquires StakeAccount {
        let sender_addr = signer::address_of(sender);
        let stake_obj = borrow_global_mut<StakeAccount>(sender_addr);
        assert!(stake_obj.stake_account.amount >= amount, 1);
        stake_obj.stake_account.amount = stake_obj.stake_account.amount - amount;

        let extend_ref = &stake_obj.extend_ref;
        let externd_ref_obj = &object::generate_signer_for_extending(extend_ref);
        primary_fungible_store::transfer(externd_ref_obj, fa, sender_addr , amount);
    }
    
    #[view]
    public fun get_epoch_rate(): u64 acquires Config {
        let config = borrow_global<Config>(@aptos_tutorial);
        config.epoch_rate
    }

    #[view] 
    public fun get_deposit_amount(sender: address): u64 acquires StakeAccount {
        let stake_obj = borrow_global<StakeAccount>(sender);
        stake_obj.stake_account.amount
    }

    #[test_only]
    public fun init_module_for_test(sender: &signer) {
        let config = Config {
            treasury: option::none(),
            epoch_rate: 0,
            total_staked: 0,
            total_rewards: 0,
            total_withdraw: 0,
            total_claim_rewards: 0
        };
        let constructor_ref = &object::create_named_object(sender, STAKING_FA_CONFIG);
        let config_signer = &object::generate_signer(constructor_ref);
        
        move_to(config_signer, config);
    }
}