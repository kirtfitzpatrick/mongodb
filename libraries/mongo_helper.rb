require 'chef/mixin/shell_out'

module MongoHelper
  extend self

  class ReplSet
    include Chef::Mixin::ShellOut

    def initialize(recipe)
      @recipe = recipe
    end

    def planned_primary
      @recipe.node[:mongodb][:replset][:nodes].sort_by {|a| a[:node_name]}.first
    end

    def private_ips
      @private_ips ||= @recipe.node[:mongodb][:replset][:nodes].collect do |replset_node| 
        replset_node[:private_ip]
      end.compact
    end

    def private_ip(node)
      matching_replset_node = @recipe.node[:mongodb][:replset][:nodes].find do |replset_node|
        node.name == replset_node[:node_name]
      end

      return matching_replset_node[:private_ip]
    end

    def master_ip
      Chef::Log.info "private_ips: #{private_ips.inspect}"

      @master_ip ||= private_ips.find do |ip|
        no_replset_cmd = "echo 'rs.status()' | mongo --host #{ip} | grep -q 'not running with --replSet'"
        is_master_cmd = "echo 'db.isMaster()' | mongo --host #{ip} | grep -q '\"ismaster\" : true'"

        Chef::Log.info no_replset_cmd
        Chef::Log.info is_master_cmd
        
        no_replset = shell_out(no_replset_cmd).exitstatus == 0
        is_master  = shell_out(is_master_cmd).exitstatus == 0

        if !no_replset && is_master
          Chef::Log.info "Master Found: #{ip}"
          true
        else
          Chef::Log.info "Non-master node: #{ip}"
          false
        end
      end

      @master_ip
    end

    def initialized?
      cmd = shell_out "echo 'rs.status()' | mongo local | grep -q 'run rs.initiate'"
      cmd.exitstatus != 0
    end

    def initiate(node)
      Chef::Log.info node[:mongodb][:replset][:node_name]
      Chef::Log.info "echo 'rs.initiate({ _id: \"%s\", members : [ { _id : 0, host : \"%s\"} ] })' | mongo local" % [ node[:mongodb][:replset][:node_name], private_ip(node) ]
      
      shell_out(
        "echo 'rs.initiate({ _id: \"%s\", members : [ { _id : 0, host : \"%s\"} ] })' | mongo local" %
            [ node[:mongodb][:replset][:node_name], private_ip(node) ]
      )
    end

    def next_node_id
      # Nasty little command to pull node ids out of json output
      cmd = "echo 'rs.status()' | mongo --host #{master_ip} | grep _id | cut -d : -f 2 | cut -d , -f 1"
      Chef::Log.info cmd
      shell_out(cmd).stdout.split("\n").map { |n| n.to_i }.sort.last + 1
    end

    def add_node(node)
      mongo_host   = private_ip(node)
      arbiter_only = node[:mongodb][:replset][:arbiter] ? 'true' : 'false'

      if node[:mongodb][:replset][:arbiter]
        Chef::Log.info "echo 'rs.addArb(\"#{mongo_host}\")' | mongo --host #{master_ip}"
        shell_out( "echo 'rs.addArb(\"#{mongo_host}\")' | mongo --host #{master_ip}" )
      else
        Chef::Log.info "echo 'rs.add(\"#{mongo_host}\")' | mongo --host #{master_ip}"
        shell_out( "echo 'rs.add(\"#{mongo_host}\")' | mongo --host #{master_ip}" )
      end
    end
  end
end

