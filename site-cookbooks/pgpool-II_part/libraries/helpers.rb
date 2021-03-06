#
# Cookbook Name:: pgpool-II_part
# Library:: helpers
#
#

require 'timeout'
require 'mixlib/shellout'

class Pgpool2Part
  module Helpers
    def servers(role)
      node['cloudconductor']['servers'].select { |_name, server| server['roles'].include?(role) }
    end

    def conf(key)
      node['pgpool_part'][key]
    end

    def exec_command(cmd)
      context = Mixlib::ShellOut.new(cmd)
      context.run_command
      context.error? == false
    end

    def wait_unless_completed_database
      port = conf('postgresql')['port']

      Timeout.timeout(conf('wait_timeout')) do
        p db_servers
        servers('db').each do |hostname, _server|
          until exec_command("hping3 -S #{primary_private_ip(hostname)} -p #{port} -c 5 | grep 'sport=#{port} flags=SA'")
            puts "... waiting for completed database (#{primary_private_ip(hostname)}):#{port}) ..."
            sleep conf('wait_interval')
          end
        end
      end
    end

    def backend_hostname(index)
      conf('pgconf')["backend_hostname#{index}"]
    end

    def pgpool_service
      resources('service[pgpool]')
    end

    def backend_status_check(index)
      params = []
      params << '0'
      params << 'localhost'
      params << '9898'
      params << conf('user')
      params << generate_password('pcp')

      until exec_command("pcp_node_info --verbose #{params.join(' ')} #{index}")
        puts '... pcp server is during the initialization ...'
        sleep conf('wait_interval')
      end

      while exec_command("pcp_node_info --verbose #{params.join(' ')} #{index} | grep -E 'Status *: +[03]' ")
        puts "... #{backend_hostname(index)} is during the initialization ..."
        exec_command("pcp_attach_node #{params.join(' ')} #{index}")
        pgpool_service.run_action(:restart)
        sleep conf('wait_interval')
      end
    end

    def wait_until_attached_to_backend
      Timeout.timeout(conf('wait_timeout')) do
        backend_status_check(0)
        backend_status_check(1)
      end
    end
  end
end
