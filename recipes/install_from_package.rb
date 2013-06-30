#
# Cookbook Name::       cassandra
# Description::         Install From Package
# Recipe::              install_from_package
# Author::              Benjamin Black
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

case node.platform_family
when "debian"
	apt_repository "datastax" do
		uri           "http://debian.datastax.com/community"
		components    ["stable", "main"]
		key           "http://debian.datastax.com/debian/repo_key"
	end
when "rhel"
	yum_repository "datastax" do
		url           "http://rpm.datastax.com/community"
		description   "DataStax Repo for Apache Cassandra"
	end
else
	raise RuntimeError, "Platform family #{node.platform_family} is not supported"
end

package "dsc12" do
  action :install
end

node.default['cassandra']['jar_path'] = "/usr/share/cassandra"
node.default['cassandra']['home_dir'] = "/usr/share/cassandra"