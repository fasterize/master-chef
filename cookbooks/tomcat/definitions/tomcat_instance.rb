
define :tomcat_instance, {
  :war_url => nil,
  :war_location => nil,
  :xml_config_file => nil,
  :override => {},
} do

  tomcat_instance_params = params

  config = tomcat_config tomcat_instance_params[:name]

  config = config.deep_merge tomcat_instance_params[:override]

  instance_name = config[:name]

  catalina_base = "#{node.tomcat.instances_base}/#{config[:name]}"

  [
    "#{catalina_base}",
    "#{catalina_base}/temp",
    "#{catalina_base}/webapps",
    "#{catalina_base}/work",
    "#{node.tomcat.log_dir}/#{config[:name]}"
    ].each do |d|
    directory d do
      owner node.tomcat.user
    end
  end

  bash "copy config #{catalina_base}/conf" do
    user node.tomcat.user
    code "cp -r #{node.tomcat.catalina_home}/conf #{catalina_base}/conf && rm #{catalina_base}/conf/server.xml"
    not_if "[ -d #{catalina_base}/conf ]"
  end

  link "#{catalina_base}/logs" do
    owner node.tomcat.user
    to "#{node.tomcat.log_dir}/#{config[:name]}"
  end

  template "/etc/init.d/#{config[:name]}" do
    cookbook "tomcat"
    source "init_d.erb"
    mode 0755
    variables({
      :catalina_base => catalina_base,
      :catalina_home => node.tomcat.catalina_home,
      :name => config[:name],
      :user => node.tomcat.user,
      })
  end

  service "#{config[:name]}" do
    supports :status => true, :restart => true, :reload => true, :graceful_restart => true
    action auto_compute_action
  end

  Chef::Config.exception_handlers << ServiceErrorHandler.new(config[:name], catalina_base)

  template "#{catalina_base}/conf/env" do
    cookbook "tomcat"
    source "env.erb"
    owner "tomcat"
    mode 0644
    variables :config => config
    notifies :restart, resources(:service => config[:name])
  end

  template "#{catalina_base}/conf/server.xml" do
    cookbook "tomcat"
    source "server.xml.erb"
    owner node.tomcat.user
    variables :config => config
    notifies :restart, resources(:service => config[:name])
  end

  if tomcat_instance_params[:war_location] && tomcat_instance_params[:war_url]
    war_file = "#{tomcat_instance_params[:war_location][1..-1]}.war"
    war_full_file = "#{catalina_base}/webapps/#{war_file}"
    bash "install war from url #{config[:name]}" do
      user node.tomcat.user
      code "curl --location #{tomcat_instance_params[:war_url]} -o /tmp/#{war_file} && mv /tmp/#{war_file} #{war_full_file}"
      not_if "[ -f #{war_full_file} ]"
    end
  end

  if tomcat_instance_params[:xml_config_file]

    directory "#{catalina_base}/conf/Catalina/localhost" do
      recursive true
      owner node.tomcat.user
    end

    template "#{catalina_base}/conf/Catalina/localhost/#{tomcat_instance_params[:xml_config_file][:name]}" do
      cookbook tomcat_instance_params[:xml_config_file][:cookbook] if tomcat_instance_params[:xml_config_file][:cookbook]
      source tomcat_instance_params[:xml_config_file][:source] if tomcat_instance_params[:xml_config_file][:source]
      user node.tomcat.user
      variables tomcat_instance_params[:xml_config_file][:variables] if tomcat_instance_params[:xml_config_file][:variables]
      notifies :restart, resources(:service => config[:name])
    end

  end

  catalina_base

end