Redis-Bank
==========

A Redis-backed bank for the Money gem.

Usage
-----

  Same as the VariableExchangeBank for now.

```ruby
Money.bank = RedisBank.new
Money.bank.add_rate("USD", "CAD", 1.24515)
Money.bank.add_rate("CAD", "USD", 0.803115)
Money.us_dollar(100).exchange_to("CAD") => Money.ca_dollar(124)
Money.ca_dollar(100).exchange_to("USD") => Money.us_dollar(80)
```
