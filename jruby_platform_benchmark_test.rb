require 'dalli'
require 'spymemcached'
require 'memcached'
require 'benchmark'

def set_obj(m, n)
  n.times do
    m.set @key1, @obj, 0
    m.set @key2, @obj, 0
    m.set @key3, @obj, 0
    m.set @key1, @obj, 0
    m.set @key2, @obj, 0
    m.set @key3, @obj, 0
  end
end

def set_str(m, n)
  n.times do
    m.set @key1, @str, 0
    m.set @key2, @str, 0
    m.set @key3, @str, 0
    m.set @key1, @str, 0
    m.set @key2, @str, 0
    m.set @key3, @str, 0
  end
end

def get_str(m, n)
  m.set @key1, @str, 0
  m.set @key2, @str, 0
  m.set @key3, @str, 0
  get(m, n)
end

def get_obj(m, n)
  m.set @key1, @obj, 0
  m.set @key2, @obj, 0
  m.set @key3, @obj, 0
  get(m, n)
end

def get(m, n)
  n.times do
    m.get @key1
    m.get @key2
    m.get @key3
    m.get @key1
    m.get @key2
    m.get @key3
  end
end

def multiget(m, n)
  m.set @key1, @str, 0
  m.set @key2, @str, 0
  m.set @key3, @obj, 0
  m.set @key4, @obj, 0
  c = if m.is_a?(Memcached::Rails)
    lambda do
      m.get_multi [@key1, @key2, @key3, @key4, @key5, @key6]
    end
  else
    lambda { m.get_multi @key1, @key2, @key3, @key4, @key5, @key6 }
  end
  n.times(&c)
end

def missing(m, n)
  n.times do
    begin m.delete @key1; rescue; end
    begin m.get @key1; rescue; end
    begin m.delete @key2; rescue; end
    begin m.get @key2; rescue; end
    begin m.delete @key3; rescue; end
    begin m.get @key3; rescue; end
  end
end

def mixed(m, n)
  n.times do
    m.set @key1, @obj
    m.set @key2, @obj
    m.set @key3, @obj
    m.get @key1
    m.get @key2
    m.get @key3
    m.set @key1, @obj
    m.get @key1
    m.set @key2, @obj
    m.get @key2
    m.set @key3, @obj
    m.get @key3
  end
end

@obj = {:hello => 'world'}
@str = "L-32" * 50

@servers = ["127.0.0.1:11211", "localhost:11211"]
@key1 = "Short"
@key2 = "Sym1-2-3::45"*8
@key3 = "Long"*40
@key4 = "Medium"*8
# 5 and 6 are only used for multiget miss test
@key5 = "Medium2"*8
@key6 = "Long3"*40

require 'rbconfig'

threads = ARGV.first.to_i.times.to_a

puts "Memcache client benchmark, JRuby[#{Config::CONFIG['ruby_version']}, #{Config::CONFIG['arch']}, #{Config::CONFIG['target_os']}]"
puts "#{threads.size} threads"

@dalli = threads.map {|ns| Dalli::Client.new(@servers, :compress => true, :namespace => "dalli-#{ns}")}
@spy = threads.map {|ns| Spymemcached.new(@servers, :namespace => "spy-#{ns}") }
@memcached = threads.map do |ns|
  Memcached::Rails.new(@servers, {
    :exception_retry_limit => 0,
    :binary_protocol => true,
    :should_optimize => true,
    :transcoder => 'marshal_zlib',
    :namespace => "jm-#{ns}"
  })
end

clients = {
  'dalli' => @dalli,
  'spymemcached.jruby' => @spy,
  'jruby-memcached' => @memcached
}.to_a

Benchmark.bm(30) do |x|
  n = 25000
  [:set_str, :get_str, :set_obj, :get_obj, :multiget, :missing, :mixed].each do |m|
    puts "#{m}:"
    clients.shuffle.each do |name, clients|
      x.report("  #{name}") do
        ts = clients.map do |client|
          Thread.start do
            send(m, client, n)
          end
        end
        ts.each(&:join)
      end
    end
  end
end
