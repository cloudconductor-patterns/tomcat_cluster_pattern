require 'spec_helper'

describe port(5432) do
  it { should be_listening.with('tcp') }
end

describe 'postgresql server' do
  database = 'postgres'
  root_user = 'postgres'

  params = property[:consul_parameters]

  session_db = 'session'
  app_db = 'application'

  tomcat_user = 'tomcat'
  app_user = 'application'
  rep_user = 'replication'
  rep_chk_user = 'repcheck'

  if params['postgresql_part']
    config = params['postgresql_part']

    if config['tomcat_session']
      session_db = config['tomcat_session']['database'] if config['tomcat_session']['database']
      tomcat_user = config['tomcat_session']['user'] if config['tomcat_session']['user']
    end

    if config['application']
      app_db = config['application']['database'] if config['application']['database']
      app_user = config['application']['user'] if config['application']['user']
    end

    if config['replication']
      rep_user = config['replication']['user'] if config['replication']['user']
      rep_chk_user = config['replication']['check_user'] if config['replication']['check_user']
    end
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{database} -c '\\l'") do
    its(:exit_status) { should eq 0 }
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{session_db} -c '\\l'") do
    its(:exit_status) { should eq 0 }
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{app_db} -c '\\l'") do
    its(:exit_status) { should eq 0 }
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{database} -c '\\dg' | grep #{tomcat_user}") do
    its(:exit_status) { should eq 0 }
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{database} -c '\\dg' | grep #{app_user}") do
    its(:exit_status) { should eq 0 }
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{database} -c '\\dg' | grep #{rep_user}") do
    its(:exit_status) { should eq 0 }
  end

  describe command("sudo -u postgres psql -U #{root_user} -d #{database} -c '\\dg' | grep #{rep_chk_user}") do
    its(:exit_status) { should eq 0 }
  end
end
