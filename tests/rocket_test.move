module games::rocket_test {
    use std::string::utf8;
    
    use sui::test_scenario as ts;

    use rocket::rocket::{Game, Instance, RocketOwnerCap};
    use rocket::rocket::{test_init, new, buy_ticket, finalize};
    use sui::coin::{mint_for_testing};


    const OWNER: address = @0x99;
    const PLAYER_1: address = @0x0A;
    const PLAYER_2: address = @0x1A;
    const PLAYER_3: address = @0x2A;

    const SATS_PER_BTC:u64 = 1e8;
    const TICKET_PRICE:u64 = 10000;

     fun init_test() : ts::Scenario{
        // first transaction to emulate module initialization
        let scenario_val = ts::begin(OWNER);
        let scenario = &mut scenario_val;
        {
            test_init(ts::ctx(scenario));
        };
        scenario_val
    }

    fun create_new_rocket(scenario: &mut ts::Scenario) {
         ts::next_tx(scenario, OWNER);
        {
            let cap = ts::take_from_sender<RocketOwnerCap>(scenario);
            new(&cap, utf8(b"BTC"), TICKET_PRICE, 1 ,ts::ctx(scenario));
            ts::return_to_sender(scenario, cap);
        };
    }

    fun buy_ticket_helper(addr:address, scenario: &mut ts::Scenario) {
         ts::next_tx(scenario, addr);
        {
            let game = ts::take_shared<Game>(scenario);
            let instance = ts::take_shared<Instance>(scenario);
            buy_ticket(&mut game, &mut instance, mint_for_testing(TICKET_PRICE, ts::ctx(scenario)), 45000, ts::ctx(scenario));
            ts::return_shared(game);
            ts::return_shared(instance);
        };
    }

}