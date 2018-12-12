#
# Vagrantfile for perfSONAR Testbed Host

require 'netaddr'
require 'yaml'

config_user =    YAML.load(File.read("config.yaml"))
config_global =  YAML.load(File.read("global.yaml"))
config_testbed = YAML.load(File.read("testbeds/#{config_user["testbed"]}.yaml"))

config = config_global.merge(config_testbed).merge(config_user)



Vagrant.configure("2") do |vc|

  # TODO: Need to be able to handle Debian and anything else we support.
  vc.vm.box = "centos/7"


  #
  # Plugins
  #

  plugins = %w(netaddr)

  plugins_needed = plugins.select { |plugin| not Vagrant.has_plugin? plugin }
  if plugins_needed.any?
    abort "Missing plugins: #{plugins_needed.join(" ")}"
  end


  #
  # VirtualBox
  #

  vc.vm.provider "virtualbox" do |vb|

    vb.cpus = 4
    vb.memory = 4096

    # Don't need the guest extensions on this host.
    if Vagrant.has_plugin?("vagrant-vbguest")
      vc.vbguest.auto_update = false
    end

  end

  #
  # General
  #

  vc.vm.hostname = config.fetch("host-name", "unnamed-host") 


  #
  # Network
  #

  host_number = config["host-number"]
  route_table_base = 10
  route_table_num = route_table_base

  config["network"].each do |key, value|

    host_if = value["bridge"]
    guest_if = key
    vc.vm.network "public_network", bridge: host_if, auto_config: false

    vc.vm.provision "network-route-flush-#{guest_if}-#{route_table_num}", type: "shell", run: "always", inline: <<-SHELL
      ip route flush table #{route_table_num}
    SHELL

    [ 4, 6 ].each do |family|

      net_entry = value["ip"][family]
      next if net_entry == nil

      block = net_entry["block"]
      next if block == nil

      case family
      when 4
        net = NetAddr::IPv4Net.parse("#{block}")
      when 6
        net = NetAddr::IPv6Net.parse(block)
      else
        raise "Internal error: Unknown IP family #{family}"
      end

      # Addressing

      if not (1..net.len) === host_number
          if net.len > 0
            abort "Host number for a #{net.netmask.to_s} must be 1..#{net.len - 2}."
          else
            warn "Netblock #{block} is too large to validate host number.  Proceeding."
          end
      end
      
      addr = net.nth(host_number)
      vc.vm.provision "network-#{guest_if}-ipv#{family}", type: "shell", run: "always", inline: <<-SHELL
        ip -#{family} address replace #{addr}#{net.netmask} dev #{guest_if}
        ip -#{family} address show dev #{guest_if}
      SHELL

      # Default Routes (later entries override earlier ones)

      default = net_entry["default"]
      next if default == nil

      vc.vm.provision "network-routing-#{guest_if}-ipv#{family}", type: "shell", run: "always", inline: <<-SHELL

        defroute()
        {
            ip -#{family} route list table #{route_table_num} | egrep -e '^default '
        }
        OLD_DEFAULT=$(defroute)
        if [ -n "${OLD_DEFAULT}" ]
        then
            echo "Replacing existing default route ${OLD_DEFAULT}"
            ip -#{family} route del default table #{route_table_num}
        fi

        # Traffic sourced from this interface goes out the same way.
        ip -#{family} route add default via "#{default}" dev "#{guest_if}" table #{route_table_num}
        ip -#{family} rule add from #{addr} table #{route_table_num}

        # The global default route is via the first interface.
        if [ "#{route_table_num}" -eq "#{route_table_base}" ]
        then
            ip -#{family} route list | egrep -e '^default ' \
              && ip -#{family} route del default
            ip -#{family} route add default via "#{default}" dev "#{guest_if}"
            echo "Global IPv#{family} default route via #{default} on #{guest_if}"
        fi
      SHELL

    end

    route_table_num += 1

  end


  #
  # perfSONAR
  #

  vc.vm.provision "perfSONAR", type:"shell", run: "once", inline: <<-SHELL

    YUMMY="yum -y"

    ${YUMMY} install epel-release
    ${YUMMY} install "#{config["perfsonar-repo"]}"

    case "#{config["repository"]}" in
      production)
        true  # Nothing to do here.
        ;;
      staging)
        ${YUMMY} install perfSONAR-repo-staging
        ;;
      nightly)
        ${YUMMY} install perfSONAR-repo-staging install perfSONAR-repo-nightly
        ;;
      *)
        echo "Unknown repository '#{config["repository"]}'" 1>&2
        exit 1
    esac

    ${YUMMY} clean all
    ${YUMMY} update
    ${YUMMY} install perfsonar-toolkit

    # Disable SSH root login
    sed -i -e 's/PermitRootLogin.*$/PermitRootLogin no/g' /etc/ssh/sshd_config
    systemctl restart sshd

  SHELL

end


# -*- mode: ruby -*-
# vi: set ft=ruby :
