#[test_only]
module token_vesting::token_vesting_tests;
// uncomment this line to import the module
use token_vesting::token_vesting::{Self, TOKEN_VESTING, Minted, LOCKED_MINT, Locker, WithdrawVested};

use sui::coin::{Coin, TreasuryCap};
use sui::test_scenario;
use sui::clock;
use sui::event;
use std::debug;

#[test]
fun test_initliazation() {
    let deployer = @0x1;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };

    test_scenario::end(scenario);
}

#[test]
fun test_mint_and_transfer() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 2000; //2.000DVD
        token_vesting::mint_token(&mut treasury_cap, amount, receiver, scenario.ctx());

        test_scenario::return_shared(treasury_cap);
    };

    test_scenario::end(scenario);
}

#[test]
fun test_burn_token() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 2000; //2.000DVD
        token_vesting::mint_token(&mut treasury_cap, amount, receiver, scenario.ctx());

        test_scenario::return_shared(treasury_cap);
    };
    scenario.next_tx(receiver);
    {
        let coin = test_scenario::take_from_address<Coin<TOKEN_VESTING>>(&scenario, receiver);

        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        token_vesting::burn_token(&mut treasury_cap, coin);

        test_scenario::return_shared(treasury_cap);
    };

    test_scenario::end(scenario);
}

#[test]
fun test_mint_total_amount() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 2000; //2.000DVD
        token_vesting::mint_token(&mut treasury_cap, amount, receiver, scenario.ctx());

        test_scenario::return_shared(treasury_cap);
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 2000; //2.000DVD
        token_vesting::mint_token(&mut treasury_cap, amount, receiver, scenario.ctx());

        let mut events = event::events_by_type<Minted>();
        // debug::print(&events);

        let _minted: Minted = events.remove(0);

        // debug::print(&minted);

        test_scenario::return_shared(treasury_cap);
    };

    test_scenario::end(scenario);
}

#[test]
fun test_locked_mint() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 200000; //200.000DVD
        let lock_up_duration = 1000;
        let test_clock = clock::create_for_testing(scenario.ctx());

        token_vesting::locked_mint(&mut treasury_cap, receiver, amount, lock_up_duration, &test_clock , scenario.ctx());

        let _events = event::events_by_type<LOCKED_MINT>();
        // debug::print(&events);

        test_clock.destroy_for_testing();

        test_scenario::return_shared(treasury_cap);
    };
    test_scenario::end(scenario);
}

#[test]
fun test_withdraw_vesting() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 200000; //200.000DVD
        let lock_up_duration = 1000;
        let test_clock = clock::create_for_testing(scenario.ctx());

        token_vesting::locked_mint(&mut treasury_cap, receiver, amount, lock_up_duration, &test_clock , scenario.ctx());

        let _events = event::events_by_type<LOCKED_MINT>();
        // debug::print(&events);

        test_clock.destroy_for_testing();

        test_scenario::return_shared(treasury_cap);
    };
    scenario.next_tx(receiver);
    {
        let mut locker = test_scenario::take_from_sender<Locker>(&scenario);

        let mut test_clock = clock::create_for_testing(scenario.ctx());

        test_clock.increment_for_testing(1200);

        token_vesting::withdraw_vested(&mut locker, &test_clock, scenario.ctx());

        let mut events = event::events_by_type<WithdrawVested>();

        let _withdrawVested: WithdrawVested = vector::remove(&mut events, 0);

        // debug::print(&withdrawVested);


        test_clock.destroy_for_testing();
        test_scenario::return_to_sender(&scenario, locker);
    };
    test_scenario::end(scenario);
}

#[test]
fun test_withdraw_half() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 200000; //200.000DVD
        let lock_up_duration = 1000;
        let test_clock = clock::create_for_testing(scenario.ctx());

        token_vesting::locked_mint(&mut treasury_cap, receiver, amount, lock_up_duration, &test_clock , scenario.ctx());

        let _events = event::events_by_type<LOCKED_MINT>();
        // debug::print(&events);

        test_clock.destroy_for_testing();

        test_scenario::return_shared(treasury_cap);
    };
    scenario.next_tx(receiver);
    {
        let mut locker = test_scenario::take_from_sender<Locker>(&scenario);

        let mut test_clock = clock::create_for_testing(scenario.ctx());

        test_clock.increment_for_testing(500);

        token_vesting::withdraw_vested(&mut locker, &test_clock, scenario.ctx());

        let mut events = event::events_by_type<WithdrawVested>();

        let _withdrawVested: WithdrawVested = vector::remove(&mut events, 0);

        // debug::print(&withdrawVested);


        test_clock.destroy_for_testing();
        test_scenario::return_to_sender(&scenario, locker);
    };
    test_scenario::end(scenario);
}

#[test]
#[expected_failure]
fun test_withdraw_half_not_recipient() {
    let deployer = @0x1;
    let receiver = @0x2;
    let mut scenario = test_scenario::begin(deployer);

    scenario.next_tx(deployer);
    {
        token_vesting::test_init(scenario.ctx())
    };
    scenario.next_tx(deployer);
    {
        let mut treasury_cap = test_scenario::take_shared<TreasuryCap<TOKEN_VESTING>>(&scenario);

        let amount: u64 = 200000; //200.000DVD
        let lock_up_duration = 1000;
        let test_clock = clock::create_for_testing(scenario.ctx());

        token_vesting::locked_mint(&mut treasury_cap, receiver, amount, lock_up_duration, &test_clock , scenario.ctx());

        let _events = event::events_by_type<LOCKED_MINT>();
        // debug::print(&events);

        test_clock.destroy_for_testing();

        test_scenario::return_shared(treasury_cap);
    };
    scenario.next_tx(deployer);
    {
// expected to fail... since deployer has no Locker object
        let mut locker = test_scenario::take_from_sender<Locker>(&scenario);

        let mut test_clock = clock::create_for_testing(scenario.ctx());

        test_clock.increment_for_testing(500);

        token_vesting::withdraw_vested(&mut locker, &test_clock, scenario.ctx());

        let mut events = event::events_by_type<WithdrawVested>();

        let _withdrawVested: WithdrawVested = vector::remove(&mut events, 0);

        // debug::print(&withdrawVested);


        test_clock.destroy_for_testing();
        test_scenario::return_to_sender(&scenario, locker);
    };
    test_scenario::end(scenario);
}

