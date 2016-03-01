#
# Cookbook Name:: postgresql_part
# Recipe:: configure
#
#

require 'timeout'

bash 'create_pid_file' do
  pid_file = "/var/run/#{node['postgresql']['server']['service_name']}.pid"
  lock_file = "/var/lock/subsys/#{node['postgresql']['server']['service_name']}"
  postmaster_file = "#{node['postgresql']['dir']}/postmaster.pid"
  code <<-EOS
    if [ ! -f #{postmaster_file} ]; then
      exit 1
    fi
    head -n 1 #{postmaster_file} > #{pid_file}
    touch #{lock_file}
  EOS
  not_if { ::File.exist?(pid_file) }
  retries 5
end

pgpass = [
  {
    'ip' => '127.0.0.1',
    'port' => node['postgresql']['config']['port'],
    'db_name' => 'replication',
    'user' => node['postgresql_part']['replication']['user'],
    'passwd' => generate_password('db_replication')
  }, {
    'ip' => primary_db_ip,
    'port' => node['postgresql']['config']['port'],
    'db_name' => 'replication',
    'user' => node['postgresql_part']['replication']['user'],
    'passwd' => generate_password('db_replication')
  }, {
    'ip' => standby_db_ip,
    'port' => node['postgresql']['config']['port'],
    'db_name' => 'replication',
    'user' => node['postgresql_part']['replication']['user'],
    'passwd' => generate_password('db_replication')
  }
]

node['cloudconductor']['servers'].each do |_hostname, sv_info|
  next unless sv_info['roles'].include?('ap')

  pgpass << {
    'ip' => sv_info['private_ip'],
    'port' => '9999',
    'db_name' => '*',
    'user' => node['postgresql_part']['application']['user'],
    'passwd' => generate_password('db_application')
  }
end

template "#{node['postgresql_part']['home_dir']}/.pgpass" do
  source 'pgpass.erb'
  mode '0600'
  owner 'postgres'
  group 'postgres'
  variables(
    pgpass: pgpass
  )
end

if primary_db?(node['ipaddress'])
  include_recipe 'postgresql_part::configure_primary'
else
  include_recipe 'postgresql_part::configure_standby'
end

if node['postgresql_part']['pgpool-II']['use']
  event_handlers_dir = node['postgresql_part']['event_handlers_dir']
  file = File.join(event_handlers_dir, 'check-state-event-handler')
  app_user = node['postgresql_part']['application']['user']

  cmdstr = 'sed -i.bak'
  cmdstr << " -e 's/^\\(.*postgres psql.*-U \\)application\\(.*\\)/\\1#{app_user}\\2/'"
  cmdstr << " #{file}"

  execute cmdstr
end
