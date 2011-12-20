require 'chef/mixin/shell_out'

module MongoHelper
  extend self

  class ReplSet
    include Chef::Mixin::ShellOut

    def initialize(recipe)
      @recipe = recipe
    end

    def planned_primary
      @recipe.node[:mongodb][:replset].sort_by {|a| a[:name]}.first
    end

    def private_ips
      @private_ips ||= @recipe.node[:mongodb][:replset].collect do |replset_node| 
        replset_node[:private_ip]
      end.compact
    end

    def private_ip(node)
      matching_replset_node = @recipe.node[:mongodb][:replset].find do |replset_node|
        node.name == replset_node[:name]
      end

      return matching_replset_node[:private_ip]
    end

    # def master_ip
    #   @master_ip ||= private_ips.find do |ip|
    #     shell_out( "echo 'db.isMaster()' | mongo --host #{ip} | grep -q '\"ismaster\" : true'" ).exitstatus == 0
    #   end
    # end

    def master_ip
      # @master_ip ||= private_ips.find do |ip|
      #   shell_out( "echo 'db.isMaster()' | mongo --host #{ip} | grep -q '\"ismaster\" : true'" ).exitstatus == 0
      # end
      Chef::Log.info "private_ips: #{private_ips.inspect}"

      @master_ip ||= private_ips.find do |ip|
        if shell_out( "echo 'db.isMaster()' | mongo --host #{ip} | grep -q '\"ismaster\" : true'" ).exitstatus == 0
          Chef::Log.info "Master Found: #{ip}"
          true
        else
          Chef::Log.info "Non-master node: #{ip}"
          false
        end
      end

      @master_ip
    end

    # def registered_nodes
    #   @registered_nodes ||= @recipe.node[:mongodb][:replset].collect do |replset_node|
    #     ( @recipe.node.name == replset_node[:name] ) ? @recipe.node. : @recipe.search(:node, "name:#{replset_node[:name]}").first
    #   end.compact
    # end

    def initialized?
      cmd = shell_out "echo 'rs.status()' | mongo local | grep -q 'run rs.initiate'"
      cmd.exitstatus != 0
    end

    def initiate(node)
      Chef::Log.info "echo 'rs.initiate({ _id: \"%s\", members : [ { _id : 0, host : \"%s\"} ] })' | mongo local" % [ node[:mongodb][:replset_name], private_ip(node) ]
      
      shell_out(
        "echo 'rs.initiate({ _id: \"%s\", members : [ { _id : 0, host : \"%s\"} ] })' | mongo local" %
            [ node[:mongodb][:replset_name], private_ip(node) ]
      )
    end

    def next_node_id
      # Nasty little command to pull node ids out of json output
      cmd = shell_out "echo 'rs.status()' | mongo --host #{master_ip} | grep _id | cut -d : -f 2 | cut -d , -f 1"
      cmd.stdout.split("\n").map { |n| n.to_i }.sort.last + 1
    end

    def add_node(node)
      mongo_host   = private_ip(node)
      arbiter_only = node[:mongodb][:arbiter] ? 'true' : 'false'

      if node[:mongodb][:arbiter]
        Chef::Log.info "echo 'rs.addArb(\"#{mongo_host}\")' | mongo --host #{master_ip}"
        shell_out( "echo 'rs.addArb(\"#{mongo_host}\")' | mongo --host #{master_ip}" )
      else
        Chef::Log.info "echo 'rs.add(\"#{mongo_host}\")' | mongo --host #{master_ip}"
        shell_out( "echo 'rs.add(\"#{mongo_host}\")' | mongo --host #{master_ip}" )
      end
    end
  end
end

