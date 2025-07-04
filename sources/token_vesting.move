module token_vesting::token_vesting;

use sui::clock::{Self, Clock};

use sui::coin::{Self, Coin, TreasuryCap};
use sui::balance::{Self, Balance};
use sui::url::{Self, Url};
use sui::event;
use std::string::String;

///Witness
public struct TOKEN_VESTING has drop {}

public struct Locker has key, store {
    id: UID,
    start_date: u64,
    end_date: u64,
    original_balance: u64,
    current_balance: Balance<TOKEN_VESTING>
}


/// Events
public struct CreatedCurrency has drop, copy {
    name_of_token: String,
    symbol: String,
    token_image: Option<Url>,
    current_total_supply: u64

}

/// After Minting Token 
public struct Minted has drop, copy {
    recipient: address,
    amount: u64,
    current_total_supply: u64,
}

/// LockedMint
public struct LOCKED_MINT has drop, copy {
    recipient: address,
    amount: u64,
    amount_locked: u64,
    locked_period: u64
}

/// WithdrawVested
public struct WithdrawVested has drop, copy {
    recipient: address,
    amount: u64
}


/// After Burning Token
public struct Burned has drop, copy {
    current_total_supply: u64
}


fun init(witness: TOKEN_VESTING, ctx: &mut TxContext) {
    let ( treasury_cap, metadata) = coin::create_currency<TOKEN_VESTING>(witness, 3, b"DVD", b"DevDanny", b"Dev Danny Deployed Token", option::some(url::new_unsafe_from_bytes(b"https://pbs.twimg.com/profile_images/1741411753404084224/yLULBONw_400x400.jpg")), ctx);

    event::emit(CreatedCurrency {
        name_of_token: metadata.get_name() ,
        symbol: metadata.get_symbol().to_string(),
        token_image: metadata.get_icon_url(),
        current_total_supply: treasury_cap.total_supply(),
    });

    transfer::public_freeze_object(metadata);
    transfer::public_share_object(treasury_cap)

}



public fun mint_token(treasury_cap: &mut TreasuryCap<TOKEN_VESTING>, amount: u64, recipient: address, ctx: &mut TxContext){
    coin::mint_and_transfer(treasury_cap, amount, recipient, ctx);

    event::emit(Minted {
        recipient,
        amount,
        current_total_supply: treasury_cap.total_supply(),
    });

    
}

public fun burn_token(treasury_cap: &mut TreasuryCap<TOKEN_VESTING>, coin: Coin<TOKEN_VESTING>){
    coin::burn(treasury_cap, coin);

    event::emit(Burned { current_total_supply: treasury_cap.total_supply() })
}

///token vesting
public fun locked_mint(treasury_cap: &mut TreasuryCap<TOKEN_VESTING>, recipient: address, amount: u64, lock_up_duration: u64, clock: &Clock, ctx: &mut TxContext){
    let coin = coin::mint(treasury_cap, amount, ctx);
    let start_date = clock::timestamp_ms(clock);
    let end_date = lock_up_duration - start_date;

    transfer::public_transfer(Locker {
        id: object::new(ctx),
        start_date,
        end_date,
        original_balance: amount,
        current_balance: coin::into_balance(coin),
    }, recipient);

    event::emit(LOCKED_MINT {
        recipient,
        amount,
        amount_locked: amount,
        locked_period: end_date,
    });
}

public fun withdraw_vested(locker:&mut Locker, clock: &Clock, ctx: &mut TxContext){
    let total_duration = locker.end_date - locker.start_date;
    let elapsed_duration = clock::timestamp_ms(clock) - locker.start_date; 

    let total_vested_amount = if (elapsed_duration > total_duration){
        locker.original_balance
    } else {
        (locker.original_balance * elapsed_duration) /total_duration
    };


    let available_vested_amount = total_vested_amount - (locker.original_balance - balance::value(&locker.current_balance));
    transfer::public_transfer(coin::take(&mut locker.current_balance, available_vested_amount, ctx), ctx.sender());

    event::emit(WithdrawVested { recipient: ctx.sender(), amount: available_vested_amount });
}

public fun get_total_supply(minted: &Minted): u64 {
    minted.current_total_supply
}

public fun get_amount_withdrawn(withdrawVested: &WithdrawVested): u64 {
     withdrawVested.amount
}

#[test_only]
public fun test_init(ctx: &mut TxContext) {
    init(TOKEN_VESTING {}, ctx);
}

