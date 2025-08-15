module aptos_tutorial::strategy_test {
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

    // Thala Strategy Module
    use thalaswap_v2::pool::{Self, Pool}; 
    use thalaswap_v2::coin_wrapper::{Self, Notacoin};
    use thala_staked_lpt::staked_lpt; 

    const USDC: address = @usdc; 
    const USDT: address = @usdt; 
    const THALA_POOL_USDC_USDT: address = @0xc3c4cbb3efcd3ec1b6679dc0ed45851486920dba0e86e612e80a79041a6cf1a3;
    const THALA_STAKE_LP: address = @0x5b07f08f0c43104b1dcb747273c5fc13bd86074f6e8e591bf0d8c5b08720cbd4;

    #[test_only]
    use std::debug;

    fun init_module(sender: &signer) {
    } 

    public entry fun deposit_thala(sender: &signer, asset: Object<Metadata>, amount: u64) {
        let asset_addr = object::object_address(&asset);
        let pool_obj = object::address_to_object<Pool>(THALA_POOL_USDC_USDT);

        let amounts = vector::empty<u64>();
        if(asset_addr == USDC) {
            vector::push_back(&mut amounts, 0);
            vector::push_back(&mut amounts, amount);
        } else if(asset_addr == USDT) {
            vector::push_back(&mut amounts, 0);
            vector::push_back(&mut amounts, amount);
        };

        let assets = pool::pool_assets_metadata(pool_obj);
        let preview = pool::preview_add_liquidity_stable(pool_obj, assets, amounts);
        let (lp_amount, _) = pool::add_liquidity_preview_info(preview);
        
        coin_wrapper::add_liquidity_stable<Notacoin, Notacoin, Notacoin, Notacoin, Notacoin, Notacoin>(
            sender,
            object::address_to_object<Pool>(THALA_POOL_USDC_USDT),
            amounts,
            lp_amount
        );

        let thala_staked_obj = object::address_to_object<Metadata>(THALA_STAKE_LP); 

        staked_lpt::stake_entry(
            sender,
            object::address_to_object<Metadata>(THALA_POOL_USDC_USDT), 
            lp_amount,
        );
    }

    public entry fun withdraw_thala(sender: &signer) {
        let sender_addr = signer::address_of(sender);
        let pool_obj = object::address_to_object<Pool>(THALA_POOL_USDC_USDT);
        let lp_metadata_obj = object::address_to_object<Metadata>(THALA_POOL_USDC_USDT); 

        let thala_staked_obj = object::address_to_object<Metadata>(THALA_STAKE_LP); 
        let thala_staked_lp_amount = primary_fungible_store::balance(sender_addr, thala_staked_obj);

        staked_lpt::unstake_entry(
            sender,
            thala_staked_obj, 
            thala_staked_lp_amount,
        );
        
        let lp_amount = primary_fungible_store::balance(sender_addr, lp_metadata_obj); 
        let amount_obj = pool::preview_remove_liquidity(pool_obj, lp_metadata_obj, lp_amount);
        let amounts = pool::remove_liquidity_preview_info(amount_obj);

        pool::remove_liquidity_entry(
            sender,
            pool_obj,
            lp_metadata_obj,
            lp_amount,
            amounts,
        );
    }

    #[test_only]
    public fun init_module_for_test(sender: &signer) {
        init_module(sender);
    }
}