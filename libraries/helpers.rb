module ChefExt
	module Cassandra
		module Helpers
			def search_cassandra_nodes
				return node.run_context.cache["cassandra_nodes"] if node.run_context.cache.has_key? "cassandra_nodes"
				if Chef::Config[:solo]
					::Chef::Log.warn "Skipping search on chef-solo; cassandra nodes will be read from data bag cassandra item clusters. Check README for more details"
					cassandra_nodes_from_data_bag
				else
					res = partial_search(:node, "cassandra_cluster_name:#{node[:cassandra][:cluster_name]}",
							:keys => {
	              				"name" => ["name"],
	              				"fqdn" => ["fqdn"],
								"ipaddress" => ["ipaddress"],
								"cloud" => ["cloud"],
								"cassandra" => ["cassandra"]
							})
					node.run_context.cache["cassandra_nodes"] = res
					res << node.to_hash
					res.map{|n| Mash.new(n)}.uniq{|n| n["name"]}
				end
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

			def cassandra_nodes_from_data_bag
				dbi = data_bag_item("cassandra", "clusters")
				if dbi.has_key?(node["cassandra"]["cluster_name"]) and dbi[node["cassandra"]["cluster_name"]].has_key?("nodes")
				 	dbi[node["cassandra"]["cluster_name"]]["nodes"].map do |n|
						Mash.new(node["cassandra"].to_hash.merge(n))
					end
				end.push(node).uniq{|n| n["ipaddress"]}
			rescue Exception => e
				Chef::Log.warn("Failed reading nodes from data bag: #{e}")
				[Mash.new(node.to_hash)]
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
