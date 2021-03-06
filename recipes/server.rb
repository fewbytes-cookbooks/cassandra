#
# Cookbook Name::       cassandra
# Description::         Server
# Recipe::              server
# Author::              Benjamin Black (<b@b3k.us>)
#
# Copyright 2010, Flip Kromer
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

include_recipe "runit"

runit_service "cassandra" do
  options       Mash.new(node[:cassandra].to_hash)
  env({"JAVA_HOME" => node['java']['java_home']})
end

include_recipe("cassandra::authentication")

template "#{node[:cassandra][:conf_dir]}/cassandra.yaml" do
  source        "cassandra.yaml.erb"
  owner         "root"
  group         "root"
  mode          "0644"
  variables     :cassandra => node[:cassandra]
  notifies      :restart, "runit_service[cassandra]", :delayed
end

template "#{node[:cassandra][:conf_dir]}/log4j-server.properties" do
  source        "log4j-server.properties.erb"
  owner         "root"
  group         "root"
  mode          "0644"
  variables     :cassandra => node[:cassandra]
  notifies      :restart, "runit_service[cassandra]", :delayed
end

# have some fraction of the nodes announce as a seed
if (node[:cassandra][:seed_node] || (node[:facet_index].to_i % 3 == 0) )
  node.set[:cassandra][:seed] = true
end

