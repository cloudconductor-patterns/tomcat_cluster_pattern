#
# Spec:: web_configure_spec
#
#

require 'spec_helper.rb'

describe service('haproxy') do
  it { should be_running }
end

describe service('rsyslog') do
  it { should be_running }
end

describe port(80) do
  it { should be_listening.with('tcp') }
end

describe port(443) do
  it { should be_listening.with('tcp') }
end

describe 'connect web_servers' do
  web_servers = property[:servers].each_value.select do |server|
    server[:roles].include?('web')
  end

  web_servers.each do |server|
    describe host(server[:private_ip]) do
      it { should be_reachable.with(port: 80) }
    end
  end
end
