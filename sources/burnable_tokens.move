module bhogendra_addrs::BurnableToken {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin, MintCapability, BurnCapability};
    use std::string;
    use std::option;

    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;

    struct BurnableToken {}

    struct TokenCapabilities has key {
        mint_cap: MintCapability<BurnableToken>,
        burn_cap: BurnCapability<BurnableToken>,
    }

    public fun initialize_token(account: &signer) {
        let account_addr = signer::address_of(account);
        
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<BurnableToken>(
            account,
            string::utf8(b"Burnable Token"),
            string::utf8(b"BURN"),
            8, 
            true, 
        );

        move_to(account, TokenCapabilities {
            mint_cap,
            burn_cap,
        });

        coin::destroy_freeze_cap(freeze_cap);
    }

    public fun mint_tokens(
        admin: &signer, 
        to: address, 
        amount: u64
    ) acquires TokenCapabilities {
        let admin_addr = signer::address_of(admin);
        assert!(exists<TokenCapabilities>(admin_addr), E_NOT_AUTHORIZED);
        
        let capabilities = borrow_global<TokenCapabilities>(admin_addr);
        let tokens = coin::mint<BurnableToken>(amount, &capabilities.mint_cap);
        coin::deposit<BurnableToken>(to, tokens);
    }

    public fun burn_tokens(account: &signer, amount: u64) acquires TokenCapabilities {
        let account_addr = signer::address_of(account);
        
        let balance = coin::balance<BurnableToken>(account_addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        
        let tokens_to_burn = coin::withdraw<BurnableToken>(account, amount);
        
        let burn_cap = &borrow_global<TokenCapabilities>(@bhogendra_addrs).burn_cap;
        
        coin::burn<BurnableToken>(tokens_to_burn, burn_cap);
    }

}
