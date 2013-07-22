module ChefExt
	module Cassandra
		module Helpers
			def search_cassandra_nodes
				node.run_context.cache["cassandra_nodes"] ||= \
					partial_search(:node, "cassandra_cluster_name:#{node[:cassandra][:cluster_name]}",
						:keys => {
              				"name" => ["name"],
              				"fqdn" => ["fqdn"],
							"ipaddress" => ["ipaddress"],
							"cloud" => ["cloud"],
							"cassandra" => ["cassandra"]
						})
			end

			def search_cassandra_seed_nodes
				search_cassandra_nodes.select {|n| n["cassandra"]["seed"] }
			end

			def ip_for_node(other_node)
				if other_node.has_key?("cloud") and node["cloud"]
					if other_node["cloud"]["provider"] == node["cloud"]["provider"]
						other_node["cloud"]["local_ipv4"]
					else
						other_node["cloud"]["public_ipv4"]
					end
				elsif other_node.has_key?("cloud") and other_node["cloud"].has_key?(public_ipv4)
					other_node["cloud"]["public_ipv4"]
				else
					other_node["ipaddress"]
				end || other_node["ipaddress"]
			end
		end		
	end
end

# monkey patch run_conext
class Chef
	class RunContext
		def cache
			@cache ||= {}
		end
	end
end
