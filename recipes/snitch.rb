extend ChefExt::Cassandra::Helpers
require 'yaml'

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

topology_tree = cassandra_nodes.uniq{|n| n['name']}.reduce(Hash.new) do |h, n|
  dc, rack = n["cassandra"]["topology"]["dc"], n["cassandra"]["topology"]["rack"]
  h[dc] ||= Hash.new
  h[dc][rack] ||= []
  h[dc][rack] << {
    "broadcast_address" => n["cassandra"]["broadcast_address"],
    "dc_local_address"  => n["ipaddress"]
  }
  h
end.map do |dc, racks_info|
  {
    "dc_name" => dc,
    "racks" => racks_info.map {|rack, rack_nodes| {"rack_name" => rack, "nodes" => rack_nodes }}
  }
end

case node['cassandra']['endpoint_snitch']
when "SimpleSnitch", "org.apache.cassandra.locator.SimpleSnitch"
when "GossipingPropertyFileSnitch", "org.apache.cassandra.locator.GossipingPropertyFileSnitch", \
  "PropertyFileSnitch", "org.apache.cassandra.locator.PropertyFileSnitch"
  file ::File.join(node["cassandra"]["conf_dir"], "cassandra-topology.properties") do
    mode "0644"
    content topologies_content
  end
when "YamlFileNetworkTopologySnitch", "org.apache.cassandra.location.YamlFileNetworkTopologySnitch"
  file ::File.join(node["cassandra"]["conf_dir"], "cassandra-topology.yaml") do
    mode "0644"
    content({"topology" => topology_tree}.to_yaml)
  end
end
