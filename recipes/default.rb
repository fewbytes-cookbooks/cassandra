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
