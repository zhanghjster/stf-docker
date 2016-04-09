package t::lib::App::Prove::Plugin::StartRedis;
use strict;
use Test::More;

my $REDIS;
my $REDIS_CONF;
my $REDIS_DIR;
sub load {
    if ( ($ENV{STF_QUEUE_TYPE} || '') !~ /^Re(dis|sque)/) {
        return;
    }

    require File::Temp;
    require Test::TCP;

    $REDIS_DIR  = File::Temp::tempdir();
    $REDIS_CONF = File::Temp->new( DIR => $REDIS_DIR, SUFFIX => ".conf");
    $REDIS      = Test::TCP->new( code => sub {
        my $port = shift;

        diag "Generating temporary conf file for redis at: $REDIS_CONF";
        print $REDIS_CONF <<EOM;
daemonize no
pidfile $REDIS_DIR/redis.pid
port $port
bind 127.0.0.1
timeout 0
loglevel verbose
logfile t/redis.log
databases 16
save 900 1
save 300 10
save 60 10000
rdbcompression yes
dbfilename dump.rdb
dir $REDIS_DIR
slave-serve-stale-data yes
appendonly no
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
slowlog-log-slower-than 10000
slowlog-max-len 128
EOM

        diag "Starting memcached on 127.0.0.1:$port";
        exec "redis-server $REDIS_CONF";
    } );
    $ENV{ STF_REDIS_HOSTPORT } = join ":", "127.0.0.1", $REDIS->port;
}

sub END {
    undef $REDIS;
    undef $REDIS_CONF;
    undef $REDIS_DIR;
}

1;