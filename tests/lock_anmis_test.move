module aptos_tutorial::lock_ammis_test {
    use std::option::{Self, Option};
    use std::signer; 
    use std::vector;
    use std::error; 
    use aptos_std::table::{Self, Table};

    use std::string::{Self, String};
 
    use aptos_framework::account;
    use aptos_framework::timestamp::{Self, now_seconds};
    use aptos_framework::aptos_account;
    use aptos_framework::event;
    use aptos_framework::fungible_asset::{Self, Metadata};
    use aptos_framework::object::{Self, Object, ObjectCore, ExtendRef};
    use aptos_framework::primary_fungible_store;
    use aptos_framework::aptos_coin::{Self, AptosCoin};
    use aptos_framework::coin::{Self, Coin};

    use aptos_tutorial::lock_ammis; 

    fun setup_test_environment(deployer: &signer) {
        timestamp::set_time_has_started_for_testing(
            &account::create_signer_for_test(@0x1)
        );
        lock_ammis::init_module_for_test(deployer);
    }

    fun mint_apt_for_test(sender: &signer, amount: u64) {
        let fa = aptos_coin::mint_apt_fa_for_test(amount);
        primary_fungible_store::deposit(
            signer::address_of(sender),
            fa,
        );
    }
    
    #[test(deployer = @aptos_tutorial, wallet1 = @0x111, wallet2 = @0x222)]
    fun test_deposit_should_right(
        deployer: &signer, wallet1: &signer, wallet2: &signer
    ) {
        setup_test_environment(deployer);
        mint_apt_for_test(wallet1, 10000);

        let wallet1_address = signer::address_of(wallet1); 

        let pre_wallet1_aptos_balance =   coin::balance<AptosCoin>(wallet1_address);
        let deposit_amount = 1000; 

        lock_ammis::deposit(wallet1, deposit_amount,  0);
        let pos_wallet1_aptos_balance = coin::balance<AptosCoin>(wallet1_address);

        assert!(pos_wallet1_aptos_balance == pre_wallet1_aptos_balance - deposit_amount);
    }

    #[test(deployer = @aptos_tutorial, wallet1 = @0x111, wallet2 = @0x222)]
    fun test_withdraw_should_right(
        deployer: &signer, wallet1: &signer, wallet2: &signer
    ) {
        setup_test_environment(deployer);
        mint_apt_for_test(wallet1, 10000);
        let wallet1_address = signer::address_of(wallet1); 

        let pre_wallet1_aptos_balance =   coin::balance<AptosCoin>(wallet1_address);

        lock_ammis::deposit(wallet1, 1000, 0);
        lock_ammis::withdraw(wallet1, 1000);
        let pos_wallet1_aptos_balance = coin::balance<AptosCoin>(wallet1_address);
        assert!(pos_wallet1_aptos_balance == pre_wallet1_aptos_balance);
    }

    
}   