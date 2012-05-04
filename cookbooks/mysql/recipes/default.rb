package "mysql-server"

local_storage_read("mysql_password:root") do
  password = PasswordGenerator.generate 32
  Chef::Log.info "Mysql : new root password generated"
  execute "change mysql root password" do
    command "mysqladmin -u root password #{password}"
  end
  password
end

if node.mysql[:databases]

  node.mysql.databases.keys.each do |k|
    node.mysql.databases[k][:database] = k

    mysql_database "mysql:databases:#{k}" do
      instance_name k
    end

    db_config = mysql_config "mysql:databases:#{k}"

    Chef::Log.info "************************************************************"
    Chef::Log.info "Mysql database for #{k}"
    Chef::Log.info "Host          : #{db_config[:host]}"
    Chef::Log.info "Database name : #{db_config[:database]}"
    Chef::Log.info "User          : #{db_config[:username]}"
    Chef::Log.info "Password      : #{db_config[:password]}"
    Chef::Log.info "************************************************************"
  end

end