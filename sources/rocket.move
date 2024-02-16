module rocket::rocket {
    use sui::{
        tx_context::{Self, TxContext},
        coin::{Self, Coin},
        balance::{Self, Balance},
        sui::{Self,SUI},
        object::{Self, UID, ID},
        transfer,
        table::{Self, Table},
    };
     use std::{
        string::String,
        option::{Self, Option},
    };
    use rocket::price_oracle::{Self, Price};

    const EInvalidPrice:u64 = 0;
    const EInvalidInstance:u64 = 1;
    const EInvalidEpoch:u64 = 2;

    struct RocketOwnerCap has key, store {
        id:UID    
    }
    
    struct Game has key, store {
        id:UID,
        balance: Balance<SUI>,
        coin: String,
        price: u64, //ticket price
        cycle:u64, //how long does a game instance last.
        prev_id: Option<ID>,
        cur_id: ID
    }

    struct Instance has key, store {
        id:UID,
        balance: Balance<SUI>,
        picks: Table<u128, address>,
        close_at:u64
    }

    fun init(ctx: &mut TxContext) {
         transfer::transfer(RocketOwnerCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx))
    }

    #[allow(lint(share_owned))]
    public fun new(_:&RocketOwnerCap, coin:String, price:u64, cycle:u64, ctx: &mut TxContext) {
        let instance = new_instance(cycle, ctx);
        let game = new_game(&instance, coin, price, cycle, ctx);
        transfer::share_object(game);
        transfer::share_object(instance);
    }

     public fun buy_ticket(
        game: &mut Game,
        instance: &mut Instance,
        cost: Coin<SUI>,
        pick:u128,
        ctx: &mut TxContext,
     ) {
        assert!(coin::value(&cost) < game.price, EInvalidPrice);
        assert!(game.cur_id != object::id(instance), EInvalidInstance);
        balance::join(&mut game.balance, coin::into_balance(cost));
        add_pick(instance, pick, ctx)
     }

    #[allow(lint(share_owned))]
    public fun finalize(game: &mut Game, instance: Instance, price: Price, ctx: &mut TxContext) {
        assert!(instance.close_at < tx_context::epoch(ctx), EInvalidEpoch);
        let (price, _) = price_oracle::destroy(price);
        if (!has_winner(&instance, price)) {
            let new_instance = next_instance(game,&mut instance, ctx);        
            transfer::share_object(new_instance);
        } else {
            let winner = get_winner(&mut instance, price);
            let new_coin = coin::from_balance(balance::withdraw_all(&mut instance.balance), ctx);
            sui::transfer(new_coin, winner);        
        };
        destroy_instance(instance)
  }


    // Internal Functions
    fun new_game(instance: &Instance, coin:String, price:u64, cycle:u64,  ctx: &mut TxContext) : Game {
        Game {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            coin,
            price,
            cycle,
            prev_id: option::none(),
            cur_id: object::id(instance)
        }
    }

    fun new_instance(cycle:u64, ctx: &mut TxContext) : Instance {
        Instance {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            picks: table::new(ctx),
            close_at: tx_context::epoch(ctx)+cycle
        }
    }

    fun add_pick(instance: &mut Instance, coin_value:u128, ctx: &TxContext) {
        if (!table::contains(&instance.picks, coin_value)) {
            table::add(&mut instance.picks, coin_value, tx_context::sender(ctx))
        }
    }

    fun has_winner(instance: &Instance, price: u128) : bool {
        table::contains(&instance.picks, price)
    }

    fun get_winner(instance: &mut Instance, price:u128) : address {
        table::remove(&mut instance.picks, price)
    }


    #[allow(lint(share_owned))]
    fun next_instance(game: &mut Game, instance:&mut Instance, ctx: &mut TxContext) : Instance {
        assert!(game.cur_id != object::id(instance), EInvalidInstance);
        game.prev_id = option::some(object::id(instance));
        Instance {
            id: object::new(ctx),
            balance: balance::withdraw_all(&mut instance.balance),
            picks: table::new(ctx),
            close_at: tx_context::epoch(ctx)+game.cycle
        }
    }

    fun destroy_instance(instance: Instance) {
        let Instance { 
            id, 
            balance, 
            picks, 
            close_at: _,
        } = instance;
        object::delete(id);
        table::drop(picks);
        balance::destroy_zero(balance);
    }


    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(ctx)
    }

}
