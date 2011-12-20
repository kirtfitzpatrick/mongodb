default[:mongodb][:conf_file] = '/etc/mongodb.conf'
default[:mongodb][:port]      = 27017
default[:mongodb][:verbose]   = false
default[:mongodb][:journal]   = true

default[:mongodb][:replset][:initiate_replset] = false
default[:mongodb][:replset][:arbiter]          = false
default[:mongodb][:replset][:nodes]            = []

