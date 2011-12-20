
include_recipe "mongodb::10gen_repo"


template node[:mongodb][:conf_file] do
  source "mongodb.conf.erb"
  mode 0644
  owner "root"
  group "root"
  variables(
    :replset_name => node[:mongodb][:replset_name]
  )
  notifies :restart, "service[mongodb]", :immediately
end

service "mongodb"



