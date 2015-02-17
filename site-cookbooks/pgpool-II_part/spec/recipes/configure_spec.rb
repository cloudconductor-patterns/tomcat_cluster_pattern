require_relative '../spec_helper'

describe 'pgpool-II_part::configure' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  pgpool_dir = '/etc/pgpool-II'

  before do
    chef_run.node.set['pgpool_part']['user'] = 'postgres'
    chef_run.node.set['pgpool_part']['config']['dir'] = pgpool_dir
    chef_run.node.set['pgpool_part']['postgresql']['dir'] = '/var/lib/pgsql/9.4/data'
    chef_run.node.set['pgpool_part']['postgresql']['port'] = '5432'
    chef_run.node.set['pgpool_part']['pgconf']['backend_flag0'] = 'ALLOW_TO_FAILOVER'
    chef_run.node.set['pgpool_part']['pgconf']['backend_weight0'] = 1
    chef_run.node.set['cloudconductor']['servers'] = { 'foo' => { 'roles' => 'db', 'private_ip' => '127.0.0.1' } }
    chef_run.converge(described_recipe)
  end

  it 'create pcp.conf, to write pcp user and password hash, and service restart' do
    allow_any_instance_of(Chef::Resource).to receive(:generate_password).with('pcp').and_return('foobarbaz')
    allow(Digest::MD5).to receive(:hexdigest).with('foobarbaz').and_return('dummy_passwd')
    chef_run.converge(described_recipe)

    expect(chef_run).to create_file("#{pgpool_dir}/pcp.conf").with(
      owner: 'root',
      group: 'root',
      mode: '0764',
      content: 'postgres:dummy_passwd'
    )

    expect(chef_run.file("#{pgpool_dir}/pcp.conf")).to notify('service[pgpool]').to(:restart).delayed
  end

  it 'create pgpool.conf and service restart' do
    expect(chef_run).to create_template("#{pgpool_dir}/pgpool.conf").with(
      owner: 'root',
      group: 'root',
      mode: '0764'
    )

    expect(chef_run.template("#{pgpool_dir}/pgpool.conf")).to notify('service[pgpool]').to(:restart).delayed
  end

  it 'write the backend db settings to pgpool.conf' do
    expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_hostname0".ljust(25)} = '127.0.0.1'/)
    expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_port0".ljust(25)} = '5432'/)
    expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_weight0".ljust(25)} = 1/)
    expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf")
      .with_content(/#{"backend_data_directory0".ljust(25)} = '\/var\/lib\/pgsql\/9.4\/data'/)
    expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf")
      .with_content(/#{"backend_flag0".ljust(25)} = 'ALLOW_TO_FAILOVER'/)
  end

  describe 'db node there are multiple' do
    before do
      chef_run.node.set['cloudconductor']['servers'] = {
        'foo' => { 'roles' => 'db', 'private_ip' => '127.0.0.1' },
        'bar' => { 'roles' => 'db', 'private_ip' => '127.0.0.2' }
      }
      chef_run.converge(described_recipe)
    end

    it 'backend_flag1 or later is the same value as the backend_flag0' do
      expect(chef_run.node['pgpool_part']['pgconf']['backend_flag1']).to eq(chef_run.node['pgpool_part']['pgconf']['backend_flag0'])
    end

    it 'backend_weight1 or later is the same value as the backend_weight0' do
      expect(chef_run.node['pgpool_part']['pgconf']['backend_weight1']).to eq(chef_run.node['pgpool_part']['pgconf']['backend_weight0'])
    end

    it 'write to pgpool.conf all of the nodes as a backend' do
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_hostname0".ljust(25)} = '127.0.0.1'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_port0".ljust(25)} = '5432'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_weight0".ljust(25)} = 1/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf")
        .with_content(/#{"backend_data_directory0".ljust(25)} = '\/var\/lib\/pgsql\/9.4\/data'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf")
        .with_content(/#{"backend_flag0".ljust(25)} = 'ALLOW_TO_FAILOVER'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_hostname1".ljust(25)} = '127.0.0.2'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_port1".ljust(25)} = '5432'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf").with_content(/#{"backend_weight1".ljust(25)} = 1/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf")
        .with_content(/#{"backend_data_directory1".ljust(25)} = '\/var\/lib\/pgsql\/9.4\/data'/)
      expect(chef_run).to render_file("#{pgpool_dir}/pgpool.conf")
        .with_content(/#{"backend_flag1".ljust(25)} = 'ALLOW_TO_FAILOVER'/)
    end
  end
end
