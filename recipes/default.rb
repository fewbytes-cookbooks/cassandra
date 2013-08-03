#
# Cookbook Name::       cassandra
# Description::         Base configuration for cassandra
# Recipe::              default
# Author::              Benjamin Black (<b@b3k.us>)
#
# Copyright 2010, Benjamin Black
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
extend ChefExt::Cassandra::Helpers

# == Recipes

include_recipe "java"

# == Users

user "cassandra" do
	system true
end

# == Directories
([:conf_dir, :log_dir, :lib_dir, :pid_dir, :commitlog_dir, :saved_caches_dir].map {|dir| node['cassandra'][dir]} +
	node['cassandra'][:data_dirs]
).each do |dir|
	directory dir do
	  user          'cassandra' 
	  group         'root'
	  mode          '0755'
	end
end

package case node.platform_family
when "debian"
	"libjna-java"
else
	"jna"
end

ips = if node.attribute?("cloud") and node["cloud"].attribute?("provider") and node["cloud"].attribute?("public_ipv4")
		[node["cloud"]["private_ipv4"], node["cloud"]["public_ipv4"], node["ipaddress"]].uniq.compact
	else
		[node["ipaddress"]]
	end

java_ext_keystore node[:cassandra][:server_encryption_options][:keystore] do
	owner "cassandra"
	password node[:cassandra][:server_encryption_options][:keystore_password]
	cert_alias node.name
	dn "CN=#{node[:fqdn]}/O=#{node[:domain]}"
	x509_extensions "SubjectAlternativeName" => ips.map{|ip| "IP=#{ip}"}.join(",")
	with_certificate do |cert|
		node.set["cassandra"]["certificate"] = cert
	end 
end

search_cassandra_nodes.select{|n| n["cassandra"]["certificate"]}.reduce({}) do |h, n|
	h[n["name"]] = n["cassandra"]["certificate"]
	h
end.each do |_alias, cert|
	java_ext_truststore_certificate _alias do
		owner "cassandra"
		certificate cert
		truststore_path node[:cassandra][:server_encryption_options][:truststore]
		password node[:cassandra][:server_encryption_options][:truststore_password]
	end
end