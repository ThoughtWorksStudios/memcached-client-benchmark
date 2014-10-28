
Benchmarking memcached clients available on JRuby
--------------------------------------------------

Setup environment:
==================

    bundle install

Start memcached on same machine before benchmarking:

    memcached

Benchmarking:
===================

    ruby jruby_platform_benchmark_test.rb <number of threads> > <number of threads>.thread.output

example:

    ruby jruby_platform_benchmark_test.rb 2 > 2.thread.output

About the benchmarking:
====================

  The benchmarking cases are copied from Dalli test/benchmark_test.rb.
  Changed to more close to real use cases, e.g. use namespace, binary protocol, call all operations with marshal (For Spymemcached wrapper, you need do kind of marshal anyway).
  Also designed for multi-threads as JRuby supports native threads.

Benchmarked memcached clients:
====================

    dalli
    jruby-memcached-thoughtworks: jruby-memcached gem with latest spymemcached jar
    spymemcached.jruby: latest spymemcached jruby wrapper

Result:
====================

Spymemcached.jruby is leading in all of benchmarking cases. For details, checkout the thread.output files included in this repository.

