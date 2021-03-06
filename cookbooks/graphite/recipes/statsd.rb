include_recipe "nodejs"

Chef::Config.exception_handlers << ServiceErrorHandler.new("statsd", "\\/etc\\/statsd.conf")

nodejs_app "statsd" do
  user node.graphite.statsd.user
  script "stats.js"
  directory node.graphite.statsd.directory
  file_check ["#{node.graphite.statsd.directory}/current/.node_version"]
  opts "/etc/statsd.conf"
  add_log_param false
end

template "/etc/statsd.conf" do
  owner node.graphite.statsd.user
  mode 0644
  source "statsd.conf.erb"
  variables :config => node.graphite.statsd.to_hash
  notifies :restart, resources(:service => "statsd")
end

git_clone "#{node.graphite.statsd.directory}/current" do
  reference node.graphite.statsd.version
  repository node.graphite.statsd.git
  user node.graphite.statsd.user
  notifies :restart, resources(:service => "statsd")
end

file "#{node.graphite.statsd.directory}/current/.node_version" do
  owner node.graphite.statsd.user
  mode 0644
  content node.graphite.statsd.node_version
end

execute_version "nodejs version statsd" do
  command "export HOME=#{get_home node.graphite.statsd.user} && cd #{node.graphite.statsd.directory}/current && $HOME/.warp/client/node/install_node.sh"
  version node.graphite.statsd.node_version
  file_storage "#{node.graphite.directory}/.statsd"
  notifies :restart, resources(:service => "statsd")
end
