module ChefExt
	module Cassandra
		module Helpers
			def search_cassandra_nodes
				node.run_context.cache["cassandra_nodes"] ||= \
					partial_search(:node, "cassandra_cluster_name:#{node[:cassandra][:cluster_name]}",
						:keys => {
							"ipaddress" => ["ipaddress"],
							"cloud" => ["cloud"],
							"cassandra" => ["cassandra"]
						})
			end

			def search_cassandra_seed_nodes
				search_cassandra_nodes.select {|n| node["cassandra"]["seed"] }
			end
		end
		
		def ip_for_node(other_node)
			if n.attribute?("cloud") and node["cloud"]
				if n["cloud"]["provider"] == node["cloud"]["provider"]
					n["cloud"]["local_ipv4"]
				else
					n["cloud"]["public_ipv4"]
				end
			elsif n.attribute?("cloud") and n["cloud"].attribute?(public_ipv4)
				n["cloud"]["public_ipv4"]
			else
				n["ipaddress"]
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
