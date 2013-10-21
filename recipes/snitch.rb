extend ChefExt::Cassandra::Helpers

cassandra_nodes = search_cassandra_nodes

file ::File.join(node["cassandra"]["conf_dir"], "cassandra-rackdc.properties") do
	mode "0644"
	content node["cassandra"]["topology"].to_hash.map{|k,v| "#{k}=#{v}" }.join("\n")
end

topologies_content = (cassandra_nodes.map{|n| 
		"#{ip_for_node(n)}=#{n["cassandra"]["topology"]["dc"]}:#{n["cassandra"]["topology"]["rack"]}" 
		} + \
		cassandra_nodes.select{|n| n["cassandra"]["dc"] == node["cassandra"]["dc"] and n["cloud"] and n["cloud"]["public_ipv4"]}.map{|n| 
		"#{n["cloud"]["public_ipv4"]}=#{n["cassandra"]["topology"]["dc"]}:#{n["cassandra"]["topology"]["rack"]}" 
		}
		).uniq.sort.join("\n")
file ::File.join(node["cassandra"]["conf_dir"], "cassandra-topology.properties") do
	mode "0644"
	content topologies_content
end
