# Make sure you define a cluster_size in roles/WHATEVER_cluster.rb
# default[:cluster_size] = 5

# The "cassandra" data bag "clusters" item defines keyspaces for the cluster named here:
default[:cassandra][:cluster_name]      = node[:cluster_name] || "Test"

#
# Make a databag called 'cassandra', with an element 'clusters'.
# Within that, define a hash named for your cluster (the setting right above).
# now a keyspace option
# default[:cassandra][:gc_grace]                      = 864_000
# - keys_cached:                        specifies the number of keys per sstable whose
#   locations we keep in memory in "mostly LRU" order.  (JUST the key
#   locations, NOT any column values.) Specify a fraction (value less
#   than 1) or an absolute number of keys to cache.  Defaults to 200000
#   keys.
# - rows_cached:                        specifies the number of rows whose entire contents we
#   cache in memory. Do not use this on ColumnFamilies with large rows,
#   or ColumnFamilies with high write:read ratios. Specify a fraction
#   (value less than 1) or an absolute number of rows to cache.
#   Defaults to 0. (i.e. row caching is off by default)
# - comment:                            used to attach additional human-readable information about
#   the column family to its definition.
# - read_repair_chance:                 specifies the probability with which read
#   repairs should be invoked on non-quorum reads.  must be between 0
#   and 1. defaults to 1.0 (always read repair).
# - preload_row_cache:                  If true, will populate row cache on startup.
#   Defaults to false.
# - gc_grace_seconds:                   specifies the time to wait before garbage
#   collecting tombstones (deletion markers). defaults to 864000 (10
#   days). See http://wiki.apache.org/cassandra/DistributedDeletes
#
default[:cassandra][:keyspaces]         = {}

# Directories, hosts and ports        # =
default[:cassandra][:home_dir]          = '/usr/local/share/cassandra'
default[:cassandra][:conf_dir]          = '/etc/cassandra'
default[:cassandra][:log_dir]           = '/var/log/cassandra'
default[:cassandra][:lib_dir]           = '/var/lib/cassandra'
default[:cassandra][:pid_dir]           = '/var/run/cassandra'

default[:cassandra][:data_dirs]         = ["/var/lib/cassandra/data"]
default[:cassandra][:commitlog_dir]     = "/var/lib/cassandra/commitlog"
default[:cassandra][:saved_caches_dir]  = "/var/lib/cassandra/saved_caches"

default[:cassandra][:user]              = 'cassandra'
default[:cassandra][:group]             = 'nogroup'
default[:users]['cassandra'][:uid]      = 330
default[:users]['cassandra'][:gid]      = 330

default[:cassandra][:listen_addr]       = node[:ipaddress]
default[:cassandra][:seeds]             = ["127.0.0.1"]
default[:cassandra][:rpc_addr]          = "0.0.0.0"
default[:cassandra][:rpc_port]          = 9160
default[:cassandra][:storage_port]      = 7000
default[:cassandra][:ssl_storage_port]  = 7001
default[:cassandra][:jmx_dash_port]     = 7199
default[:cassandra][:mx4j_addr]  = "127.0.0.1"
default[:cassandra][:mx4j_port]  = "8081"
default[:cassandra][:jna_path]   = "/usr/share/java"

local_ips = network.interfaces.map {|iface_name, iface_info|
	iface_info[:addresses].select{|addr, info| info[:family] == "inet"}.keys
}.flatten.compact
if node.attribute? :cloud and cloud[:public_ipv4] and not local_ips.include?(cloud[:public_ipv4])
	default[:cassandra][:broadcast_address] = cloud[:public_ipv4]
end

#
# Install
#

# install_from_release
default[:cassandra][:version]           = "1.2.6"
# install_from_release: tarball url
default[:cassandra][:release_url]       = ":apache_mirror:/cassandra/:version:/apache-cassandra-:version:-bin.tar.gz"

# Git install

# Git repo location
default[:cassandra][:git_repo]          = 'git://git.apache.org/cassandra.git'
# until ruby gem is updated, use cdd239dcf82ab52cb840e070fc01135efb512799
default[:cassandra][:git_revision]      = 'master' # 'HEAD'
# JNA deb location
default[:cassandra][:jna_deb_amd64_url] = "http://debian.riptano.com/maverick/pool/libjna-java_3.2.7-0~nmu.2_amd64.deb"
# MX4J Version
default[:cassandra][:mx4j_version]      = "3.0.2"

#
# Tunables - Partitioning
#

default[:cassandra][:auto_bootstrap]    = 'true'
default[:cassandra][:authenticator]     = "org.apache.cassandra.auth.AllowAllAuthenticator"
default[:cassandra][:authorizer]        = "org.apache.cassandra.auth.AllowAllAuthorizer"
default[:cassandra][:partitioner]       = "org.apache.cassandra.dht.Murmur3Partitioner"
default[:cassandra][:endpoint_snitch]   = "org.apache.cassandra.locator.SimpleSnitch"
default[:cassandra][:dynamic_snitch]    = 'true'
default[:cassandra][:initial_token]     = ""
default[:cassandra][:hinted_handoff_enabled]       = 'true'
default[:cassandra][:max_hint_window_in_ms]        = 10800000 # 3 hours

#
# Tunables -- Memory, Disk and Performance
#
ram_in_mb = (memory[:total].sub(/kB$/,'').to_f / 1024).to_i
java_heap_size_max = [[ram_in_mb / 2, 1024].min, [ram_in_mb / 4, 8192].min].max
java_eden_size = [cpu[:total] * 100,java_heap_size_max / 4].min

default[:cassandra][:java_heap_size_min]           = "#{[java_eden_size + 100, 256].max}M"         # consider setting equal to max_heap in production
default[:cassandra][:java_heap_size_max]           = "#{java_heap_size_max}M"
default[:cassandra][:java_heap_size_eden]          = "#{java_eden_size}M"
default[:cassandra][:disk_access_mode]             = "auto"
default[:cassandra][:concurrent_reads]             = cpu[:total] * 2 # 2 per core
default[:cassandra][:concurrent_writes]            = 32              # typical number of clients
default[:cassandra][:memtable_flush_writers]       = 1               # see comment in cassandra.yaml.erb
default[:cassandra][:memtable_flush_after]         = 60
default[:cassandra][:thrift_framed_transport]      = 15              # default 15; fixes CASSANDRA-475, but make sure your client is happy (Set to nil for debugging)
default[:cassandra][:thrift_max_message_length]    = 16
default[:cassandra][:incremental_backups]          = false
default[:cassandra][:snapshot_before_compaction]   = false
default[:cassandra][:memtable_throughput]          = 64
default[:cassandra][:memtable_ops]                 = 0.3
default[:cassandra][:column_index_size]            = 64
default[:cassandra][:in_memory_compaction_limit]   = 64
default[:cassandra][:compaction_preheat_key_cache] = true
default[:cassandra][:commitlog_sync]               = "periodic"
default[:cassandra][:commitlog_sync_period]        = 10000
default[:cassandra][:flush_largest_memtables_at]   = 0.75
default[:cassandra][:reduce_cache_sizes_at]        = 0.85
default[:cassandra][:reduce_cache_capacity_to]     = 0.6
default[:cassandra][:rpc_keepalive]                = "false"
default[:cassandra][:phi_convict_threshold]        = 8
default[:cassandra][:request_scheduler]            = 'org.apache.cassandra.scheduler.NoScheduler'
default[:cassandra][:throttle_limit]               = 80           # 2x (concurrent_reads + concurrent_writes)
default[:cassandra][:request_scheduler_id]         = 'keyspace'
default[:cassandra][:native_transport_port]        = 9042
default[:cassandra][:native_transport_min_threads] = 16
default[:cassandra][:native_transport_max_threads] = 128
default[:cassandra][:num_tokens]                   = 256

default[:cassandra][:topology][:dc]                = "dc1"
default[:cassandra][:topology][:rack]              = "rack1"
default[:cassandra][:topology][:prefer_local]      = true

default[:cassandra][:open_files_limit]             = 135168

# server encryption (ssl)
default[:cassandra][:server_encryption_options][:internode_encryption] = 'none'
default[:cassandra][:server_encryption_options][:keystore] = ::File.join(cassandra[:conf_dir], ".keystore")
default[:cassandra][:server_encryption_options][:keystore_password] = "cassandra"
default[:cassandra][:server_encryption_options][:truststore] = ::File.join(cassandra[:conf_dir], ".truststore")
default[:cassandra][:server_encryption_options][:truststore_password] = "cassandra"
default[:cassandra][:server_encryption_options][:require_client_auth] = false

default[:cassandra][:package_name] = "dsc20"
default[:cassandra][:version] = "2.0.1"
