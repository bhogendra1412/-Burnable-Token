module bhogendra_addrs::BurnableToken {
    use aptos_framework::signer;
    use aptos_framework::coin::{Self, Coin, MintCapability, BurnCapability};
    use std::string;
    use std::option;

    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_INSUFFICIENT_BALANCE: u64 = 2;

    /// The BurnableToken struct representing our custom token
    struct BurnableToken {}

    /// Resource to store mint and burn capabilities
    struct TokenCapabilities has key {
        mint_cap: MintCapability<BurnableToken>,
        burn_cap: BurnCapability<BurnableToken>,
    }

    /// Initialize the burnable token with mint and burn capabilities
    public fun initialize_token(account: &signer) {
        let account_addr = signer::address_of(account);
        
        // Initialize the coin with token details
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<BurnableToken>(
            account,
            string::utf8(b"Burnable Token"),
            string::utf8(b"BURN"),
            8, // decimals
            true, // monitor_supply
        );

        // Store capabilities for future use
        move_to(account, TokenCapabilities {
            mint_cap,
            burn_cap,
        });

        // Destroy freeze capability as we don't need it
        coin::destroy_freeze_cap(freeze_cap);
    }

    /// Function to mint tokens to a specified address
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

    /// Function to burn tokens from the caller's account
    public fun burn_tokens(account: &signer, amount: u64) acquires TokenCapabilities {
        // Find the admin address (assumes first account that initialized)
        let account_addr = signer::address_of(account);
        
        // Check if user has sufficient balance
        let balance = coin::balance<BurnableToken>(account_addr);
        assert!(balance >= amount, E_INSUFFICIENT_BALANCE);
        
        // Withdraw tokens from user's account
        let tokens_to_burn = coin::withdraw<BurnableToken>(account, amount);
        
        // Get burn capability from the admin (for simplicity, assume admin is at a known address)
        // In practice, you might store admin address or have a different access pattern
        let burn_cap = &borrow_global<TokenCapabilities>(@bhogendra_addrs).burn_cap;
        
        // Burn the tokens permanently
        coin::burn<BurnableToken>(tokens_to_burn, burn_cap);
    }
}