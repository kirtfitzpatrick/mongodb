default[:mongodb][:conf_file] = '/etc/mongodb.conf'
default[:mongodb][:port]      = 27017
default[:mongodb][:verbose]   = false
default[:mongodb][:journal]   = true

default[:mongodb][:dbpath] = "/var/lib/mongodb"

# Change initial_nodes to the number of nodes you plan to spin up in 
# parallel so the don't all try to make themselves the master simultaneously
default[:mongodb][:replset][:initial_nodes]    = 3

# Set the replset:name attribute to a unique value amongst all the nodes on 
# your chef server.  This attribute will be used to find all the other nodes 
# to build the replica set.
default[:mongodb][:replset][:name]             = "rs_default"

# If you want the node to be an arbiter, set this to true.
default[:mongodb][:replset][:arbiter]          = false

# Don't do anything to the following.  They will be set programatically.
default[:mongodb][:replset][:initiate_replset] = false
default[:mongodb][:replset][:nodes]            = []

