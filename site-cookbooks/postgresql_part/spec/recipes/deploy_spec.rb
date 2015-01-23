require_relative '../spec_helper'
require 'chefspec'

describe 'postgresql_part::deploy' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  myself_hostname = 'myself'
  partner_hostname = 'partner'

  describe 'primary db is this node' do
    app_name = 'app'

    before do
      chef_run.node.set['cloudconductor']['applications'] = {
        app_name => {
          type: 'dynamic'
        }
      }
      chef_run.converge(described_recipe)

      response = format(['[{"Node":"%s","Address":"172.17.0.1","ServiceID":"db",',
                             '"ServiceName":"db","ServiceTags":["primary"],"ServicePort":5432}]'].join, myself_hostname)
      allow_any_instance_of(ConsulHelper::Helper).to receive(:serch_node_possession_tag).and_return(JSON.parse(response))
    end

    describe 'dynamic type application is included "cloudconductor applications"' do
      describe 'migration type is sql' do
        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['parameters'] = {
            migration: {
              type: 'sql'
            }
          }
          chef_run.converge(described_recipe)
        end
  
        describe 'migration url is included applications parameter' do
          it 'download migration file' do
            url = 'http://cloudconductor.org/migration.sql'
            chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['migration']['url'] = url
            chef_run.converge(described_recipe)
            expect(chef_run).to create_remote_file("#{Chef::Config[:file_cache_path]}/#{app_name}.sql").with(
              source: url
            )
          end
        end
  
        describe 'migration type is not included' do
          it 'create migration file' do
            query = 'migration sql strings'
            chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['migration']['query'] = query
            chef_run.converge(described_recipe)
            expect(chef_run).to create_file("#{Chef::Config[:file_cache_path]}/app.sql").with(
              content: query
            )
          end
        end
  
        describe 'tables is not exist in postgresql db' do
          it 'do migration' do
            db_host = '127.0.0.1'
            db_port = '5432'
            db_user = 'pgsql'
            db_pass = 'pgpass'
  
            postgresql_connection_info = {
              host: db_host,
              port: db_port,
              username: db_user,
              password: db_pass
            }
  
            chef_run.node.set['postgresql']['config']['port'] = db_port
            chef_run.node.set['postgresql_part']['application']['user'] = db_user
            chef_run.node.set['postgresql_part']['application']['password'] = db_pass
  
            db_name = 'app_db'
            chef_run.node.set['postgresql_part']['application']['database'] = db_name
  
            allow_any_instance_of(Mixlib::ShellOut).to receive(:runcommand)
            allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return('0')
  
            chef_run.converge(described_recipe)
  
            expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
              :postgresql_database,
              :query,
              db_name
            ).with(
              connection: postgresql_connection_info
            )
          end
        end
  
        describe 'tables is exist in postgresql db' do
          it 'do not migration' do
            db_name = 'app_db'
            chef_run.node.set['postgresql_part']['application']['database'] = db_name
  
            allow_any_instance_of(Mixlib::ShellOut).to receive(:runcommand)
            allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return('1')
            chef_run.converge(described_recipe)
  
            expect(chef_run).to_not ChefSpec::Matchers::ResourceMatcher.new(
              :postgresql_database,
              :query,
              db_name
            )
          end
        end
      end
    end
  end
  describe 'primary db is not this node' do
    before do
      chef_run.node.set['cloudconductor']['applications'] = {
        app_name => {
          type: 'dynamic'
        }
      }
      chef_run.converge(described_recipe)
      response = format(['[{"Node":"%s","Address":"172.17.0.1","ServiceID":"db",',
                             '"ServiceName":"db","ServiceTags":["primary"],"ServicePort":5432}]'].join, partner_hostname)
      allow_any_instance_of(ConsulHelper::Helper).to receive(:serch_node_possession_tag).and_return(JSON.parse(response))
    end

    it 'do not migration' do
      db_name = 'app_db'
      chef_run.node.set['postgresql_part']['application']['database'] = db_name
  
      allow_any_instance_of(Mixlib::ShellOut).to receive(:runcommand)
      allow_any_instance_of(Mixlib::ShellOut).to receive(:stdout).and_return('1')
      chef_run.converge(described_recipe)
  
      expect(chef_run).to_not ChefSpec::Matchers::ResourceMatcher.new(
        :postgresql_database,
        :query,
        db_name
      )
    end
  end
end
