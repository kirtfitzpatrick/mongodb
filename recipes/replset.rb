# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
# 
#  http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.


include_recipe "mongodb::default"

# Expected Attributes:
#
# default[:mongodb][:replset][:name]             = 'default'
# default[:mongodb][:replset][:initial_nodes]    = 3

# network     = node['network']
# interfaces  = network['interfaces']
# iface       = interfaces['eth1']
# addresses   = iface['addresses']
# internal_ip = addresses.keys.select { |key| addresses[key]['family'] == 'inet' }.first
# 
# if node[:mongodb][:ip_address].nil? && internal_ip
#   node.set[:mongodb][:ip_address] = internal_ip
# end

node.set[:mongodb][:ip_address] = node['fqdn']

ruby_block "mongodb-search" do
  block do
    Chef::Log.info "Mongodb Replset Name: #{node[:mongodb][:replset][:name]}"
    mongodb_nodes = search(:node, "chef_environment:#{node.chef_environment} AND \
    mongodb_replset_name:#{node[:mongodb][:replset][:name]} AND \
    recipes:mongodb\\:\\:replset")
    Chef::Log.info "Found #{mongodb_nodes.size} nodes"

    node.set[:mongodb][:replset][:nodes] = mongodb_nodes.inject([]) do |memo, n|
      if n[:mongodb][:ip_address].nil?
        Chef::Log.warn 'node internal ip is nil'
      else
        Chef::Log.info "memo node name is #{n.name}"
        memo << { :node_name => n.name, :private_ip => n[:mongodb][:ip_address] }
        Chef::Log.info memo
      end
      memo
    end

    replset = MongoHelper::ReplSet.new(self)

    if ! replset.master_ip.nil?
      Chef::Log.info "A master replica set node was found.  We should be good to go to add to the replica set."
      node.set[:mongodb][:initiate_replset] = true
    elsif mongodb_nodes.length == node[:mongodb][:replset][:initial_nodes]
      Chef::Log.info "All MongoDB nodes are up.  Setting the flag to initialize the replica set."
      node.set[:mongodb][:initiate_replset] = true
    else
      Chef::Log.info "Still waiting on the rest of the mongodb nodes to be spun up to configure the replset."
      node.set[:mongodb][:initiate_replset] = false
    end

    node.save
  end
end

# Expected Attributes:
# 
# default[:mongodb][:replset][:name]             = 'default'
# default[:mongodb][:replset][:initiate_replset] = false
# default[:mongodb][:replset][:arbiter]          = false
# default[:mongodb][:replset][:nodes]            = [
#   {:name => 'mongo1', :private_ip => 'x.x.x.x'},
#   {:name => 'mongo2', :private_ip => 'x.x.x.x'}
# ]
ruby_block "establish-replset" do
  block do
    if node[:mongodb][:initiate_replset]
      replset = MongoHelper::ReplSet.new(self)
      next if replset.planned_primary.nil?

      Chef::Log.info "Detected private ips: [#{replset.private_ips.join(', ')}]"
      Chef::Log.info "Planned primary: #{replset.planned_primary.to_json}"

      if node.name == replset.planned_primary[:node_name] && !replset.initialized?
        Chef::Log.info "Replset is not initialized, initializing..."

        Chef::Log.info "initializing node #{node}"
        replset.initiate(node)

        if replset.initialized?
          node.set[:mongodb][:id] = 0
        else
          Chef::Log.info "Unable to initialize replset, nothing further to do}"
          return
        end
      end

      if replset.master_ip.nil?
        Chef::Log.info "No master node to connect to, doing nothing"
      else
        if node[:mongodb][:id].nil?
          node.set[:mongodb][:id] = replset.next_node_id
          Chef::Log.info "Node mongo id is nil, setting to #{node[:mongodb][:id]}"
        end

        Chef::Log.info "Adding node to replset"
        replset.add_node(node)
      end
    else
      Chef::Log.info "The replset doesn't appear to be ready yet.  Waiting until the next run."
    end
  end
end
