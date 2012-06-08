Redis-Bank
==========

A Redis-backed bank for the Money gem.

Usage
-----

```ruby
redis_client = Redis.new
# Or, if you'd rather just test it out without firing up redis,
# you can just use a hash, e.g.
# redis_client = {}
Money.bank = Money::Bank::RedisBank.new redis_client
Money.bank.add_rate("USD", "CAD", 1.24515)
Money.bank.add_rate("CAD", "USD", 0.803115)
Money.us_dollar(100).exchange_to("CAD") => Money.ca_dollar(124)
Money.ca_dollar(100).exchange_to("USD") => Money.us_dollar(80)
```
