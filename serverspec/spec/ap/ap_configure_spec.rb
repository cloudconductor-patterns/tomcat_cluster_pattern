require 'spec_helper'
require 'socket'

def private_ip
  Socket.getifaddrs.find do|x|
    x.name == 'eth0' && x.addr.ipv4?
  end.addr.ip_address
end

def servers(role)
  property[:servers].each_value.select { |server| server[:roles].include?(role) }
end

describe service('tomcat7') do
  it { should be_running }
end

describe service('pgpool') do
  it { should be_running }
end

describe port(8009) do
  it { should be_listening.with('tcp') }
end

params = property[:consul_parameters]

if params['pgpool_part'] && params['pgpool_part']['pgconf'] && params['pgpool_part']['pgconf']['port']
  pgpool_port = params['pgpool_part']['pgconf']['port']
else
  pgpool_port = 9999
end
if params['pgpool_part'] && params['pgpool_part']['pgconf'] && params['pgpool_part']['pgconf']['wd_port']
  wd_port = params['pgpool_part']['pgconf']['wd_port']
else
  wd_port = 9000
end

describe port(pgpool_port) do
  it { should be_listening.with('tcp') }
end

if servers('ap').length > 1
  describe port(wd_port) do
    it { should be_listening.with('tcp') }
  end
end

describe host('localhost') do
  it { should be_reachable.with(port: pgpool_port) }
end

if servers('ap').length > 1
  servers('ap').each do |server|
    if server[:private_ip] == private_ip
      describe host('localhost') do
        it { should be_reachable.with(port: wd_port) }
      end
    else
      describe host(server[:private_ip]) do
        it { should be_reachable.with(port: wd_port) }
      end
    end
  end
end

if params['postgresql'] && params['postgresql']['config'] && params['postgresql']['config']['port']
  postgresql_port = params['postgresql']['config']['port']
else
  postgresql_port = 5432
end

servers('db').each do |server|
  describe host(server[:private_ip]) do
    it { should be_reachable.with(port: postgresql_port) }
  end
end
