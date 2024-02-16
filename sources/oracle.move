module rocket::price_oracle {
  // === Imports ===
  use std::option::{Self, Option};

  use sui::math::pow;
  use sui::object::{Self, UID};
  use sui::transfer::{share_object, transfer};
  use sui::tx_context::{Self, TxContext};

  use switchboard::math;
  use switchboard::aggregator::{Self, Aggregator};

  // === Errors ===
  const EInvalidAggregator: u64 = 0;
  const ENegativePrice: u64 = 1;

  // === Constants ===

  const PRECISION: u128 = 1_000_000_000;

  // === Structs ===

  struct OracleCap has key, store {
    id: UID
  }

  struct Oracle has key {
    id: UID,
    whitelisted: Option<address>
  }

  struct Price {
    value: u128,
    latest_timestamp: u64
  }

  // === Public-Mutative Functions ===

  fun init(ctx: &mut TxContext) {
    share_object(
      Oracle {
        id: object::new(ctx),
        whitelisted: option::none()
      }
    );

    transfer(OracleCap { id: object::new(ctx) }, tx_context::sender(ctx));
  }

  // === Public-View Functions ===

  public fun new(self: &Oracle, aggregator: &Aggregator): Price {
    assert!(aggregator::aggregator_address(aggregator) == *option::borrow(&self.whitelisted), EInvalidAggregator);

    let (latest_result, latest_timestamp) = aggregator::latest_value(aggregator);

    let (value, scaling_factor, neg) = math::unpack(latest_result);

    assert!(!neg, ENegativePrice);

    Price {
      value: value * PRECISION / (pow(10, scaling_factor) as u128),
      latest_timestamp
    }
  }

  public fun destroy(price: Price): (u128, u64) {
    let Price { value, latest_timestamp } = price;
    (value, latest_timestamp)
  }

  // === Admin Functions ===

  public fun set(_: &OracleCap, self: &mut Oracle, aggregator: &Aggregator) {
    option::fill(&mut self.whitelisted, aggregator::aggregator_address(aggregator));
  } 

  public fun unset(_: &OracleCap, self: &mut Oracle) {
    option::extract(&mut self.whitelisted);
  } 
}