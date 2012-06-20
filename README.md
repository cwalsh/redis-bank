Redis-Bank
==========

A Redis-backed Bank for the {https://github.com/RubyMoney/money Money} gem.

See {Money::Bank::RedisBank} for details.

Usage
-----

```ruby
redis_client = Redis.new
Money.bank = Money::Bank::RedisBank.new redis_client
Money.bank.add_rate("USD", "CAD", 1.24515)
Money.bank.add_rate("CAD", "USD", 0.803115)
Money.us_dollar(100).exchange_to("CAD") => Money.ca_dollar(124)
Money.ca_dollar(100).exchange_to("USD") => Money.us_dollar(80)
Money.bank.rates => {"usd_to_cad" => 1.24515,
                     "cad_to_usd" => 0.803115}
```
