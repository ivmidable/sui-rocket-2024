module games::rocket_test {
    use std::string::utf8;
    
    use sui::test_scenario as ts;

    use cohort::enrollment::{Cohort, InstructorCap};
    use cohort::enrollment::{test_init, new_cohort, toggle_signups, enroll};
    use cohort::enrollment::{update};

    const OWNER: address = @0x99;
    const PLAYER_1: address = @0x0A;
    const PLAYER_2: address = @0x1A;
    const PLAYER_3: address = @0x2A;

     fun init_test() : ts::Scenario{
        // first transaction to emulate module initialization
        let scenario_val = ts::begin(INSTRUCTOR);
        let scenario = &mut scenario_val;
        {
            test_init(ts::ctx(scenario));
        };
        scenario_val
    }
}