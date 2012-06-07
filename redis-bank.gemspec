Gem::Specification.new do |s|
  s.name = 'redis-bank'
  s.version = '0.0.1'
  s.summary = 'Redis-backed Bank for the Money gem'
  s.description = 'Redis-backed Bank for the Money gem based on the VariableExchangeBank'
  s.has_rdoc = true
  s.files = %w(
    README.md
    init.rb
    lib/redis-bank.rb
  )

  s.require_path = 'lib'
  s.authors = ["Cameron Walsh"]
  s.email = "cameron.walsh@gmail.com"
  s.homepage = ""
end
