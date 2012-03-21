include_recipe "mongodb::10gen_repo"

template node[:mongodb][:conf_file] do
  source "mongodb.conf.erb"
  mode 0644
  owner "root"
  group "root"
  variables(
    :replset_name => node[:mongodb][:replset][:name]
  )
  notifies :restart, "service[mongodb]", :immediately
end

service "mongodb"

# Install pymongo
if node[:mongodb][:install_pymongo]
  include_recipe "python"

  # Install pymongo for nagios monitoring
  python_pip "pymongo" do
    action :install
  end
end