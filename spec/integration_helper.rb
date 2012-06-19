dir = File.dirname(File.expand_path(__FILE__))
RSpec.configure do |c|
  c.before :suite do
    puts "Starting redis on port 9736 for testing"
    `redis-server #{dir}/redis-test.conf`
  end

  c.after :suite do
    pid = File.read(File.dirname(File.expand_path(__FILE__))+"/redis-test.pid")
    puts "Killing test redis server..."
    `kill #{pid}`
    sleep 1
    `rm -f #{dir}/dump.rdb`
    `rm -f #{dir}/redis.log`
  end
end
