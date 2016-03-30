require 'spec_helper.rb'

# Check Service status

describe service('httpd') do
  it { should be_running }
end

# Cehck listen port
describe port(80) do
  it { should be_listening.with('tcp') }
end

# Check connect ap servers
describe host('localhost') do
  it { should be_reachable.with(port: 8009) }
end
