#
# Cookbook Name::       cassandra
# Description::         Mx4j
# Recipe::              mx4j
# Author::              Mike Heffner (<mike@librato.com>)
#
# Copyright 2011, Benjamin Black
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

#
# Installs the MX4J jarfile for monitoring
#
# See:
# http://wiki.apache.org/cassandra/Operations#Monitoring_with_MX4J
#
#
include_recipe "maven"

directory "/usr/local/share/mx4j" do
	mode "0755"
end

maven "mx4j" do
  artifact_id   "mx4j-tools"
  group_id      "mx4j"
  destination   "/usr/local/share/mx4j"
  version       node[:cassandra][:mx4j_version]
end

link "#{node[:cassandra][:home_dir]}/lib/mx4j-tools.jar" do
  to            "/usr/local/share/mx4j/lib/mx4j-tools.jar"
    notifies    :restart, "service[cassandra]", :delayed if startable?(node[:cassandra])
end

ruby_block "set enable_jmx attribute" do
	block do
		node.set[:cassandra][:enable_mx4j] = true
	end
	only_if {::File.exists? "/usr/local/share/mx4j/lib/mx4j-tools.jar"}
end