include_recipe "mongodb::default"

# Expected Attributes:
#
# default[:mongodb][:replset][:name]             = 'default'
# default[:mongodb][:replset][:initial_nodes]    = 3
if node[:mongodb][:ip_address].nil? && !node[:cloud].nil?
  node.set[:mongodb][:ip_address] = node[:cloud][:local_ipv4]
end

ruby_block "mongodb-search" do
  block do
    Chef::Log.info "Mongodb Replset Name: #{node[:mongodb][:replset][:name]}"
    mongodb_nodes = search(:node, "mongodb_replset_name:#{node[:mongodb][:replset][:name]}")
    Chef::Log.info "Found #{mongodb_nodes.size} nodes"

    node.set[:mongodb][:replset][:nodes] = mongodb_nodes.inject([]) do |memo, n|
      unless n[:mongodb][:ip_address].nil?
        memo << { :node_name => n.name, :private_ip => n[:mongodb][:ip_address] }
      end
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

      # Chef::Log.info "Detected private ips: [#{replset.private_ips.join(', ')}]"
      # Chef::Log.info "Planned primary: #{replset.planned_primary.to_json}"

      if node.name == replset.planned_primary[:node_name] && !replset.initialized?
        Chef::Log.info "Replset is not initialized, initializing..."

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
