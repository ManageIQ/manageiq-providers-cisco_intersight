module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_servers_details
      physical_racks
      hardwares
      firmwares
    end 

    def physical_servers
      collector.physical_servers.each do |s|
        
        rack = persister.physical_racks.lazy_find(s.device_mo_id)
        # Since there is no data about the chassis on the Intersight side, I cannot obtain the data about the chassis. Setting its value to nil
        chassis = nil
        # TODO: Obtain the data about health state, hostname
        server = persister.physical_servers.build(
          :ems_ref                => s.device_mo_id,
       	  :health_state           => "unknown",  
       	  :hostname               => "dummy",  
       	  :name                   => s.name,
       	  :physical_chassis       => chassis,
          :physical_rack          => rack,  
       	  :power_state            => s.admin_power_state,
          :raw_power_state        => s.oper_power_state,
          :type                   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
        )

        persister.physical_server_computer_systems.build(
          :managed_entity => server
        )

      end
    end

    def physical_servers_details
      collector.physical_servers.each do |s|
        server = persister.physical_servers.lazy_find(s.device_mo_id)
        temp = "dummy"
        # TODO: Go through the data about the servers and obtain the data about the atributes, which at the moment hold value temp.
       	persister.physical_server_details.build(
       	  :description        => temp,
      	  :location        => temp,
      	  :location_led_state        => temp,
      	  :machine_type        => temp,
      	  :manufacturer        => temp,
      	  :model        => s.model,
      	  :product_name        => s.name,
      	  :rack_name        => s.server_id,
      	  :resource        => server,
          :room        => temp,
          :serial_number        => s.serial,
        )
      end
    end

    def hardwares
      collector.physical_servers.each do |s|
        server = persister.physical_servers.lazy_find(s.device_mo_id)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => s.num_cpus,
          :disk_capacity   => s.total_memory, # TODO: Replace this atribute, since it's not the right one.
          :memory_mb       => 0, # TODO: Reformat total memory and write it to mb && replace 0 with that value
          :cpu_speed       => s.cpu_capacity,
       	  :disk_free_space => s.available_memory # TODO: Replace this atribute, since it's not the right one.
        )

	adapters_current = collector.physical_server_network_devices.select { |c| c.registered_device.moid == s.registered_device.moid }
        (adapters_current || []).each  do |net_adapter|
          # TODO: Write atributes about the parent ID - set its value net_adapter.registered_device.moid
          persister.physical_server_network_devices.build(
       	    :hardware     => hardware,
       	    :device_name  => net_adapter.dn,
            # TODO (tjazsch): Change the device type => "ethernet" to the actual device_type - minor problems with MiQ core implementation
       	    :device_type  => "ethernet", # net_adapter.model,
       	    :manufacturer => "unknown", # no data about the manufacturer - setting its value to unknown.
       	    :model        => net_adapter.model,
            :uid_ems	  => net_adapter.registered_device.moid + "-" + net_adapter.dn
             # get_temporary_unique_identifyer(net_adapter.registered_device.moid, net_adapter.dn)
          )
        end
      end
    end

    def get_temporary_unique_identifyer(moid, dn)
      # Temporarily forming the uniquie identifyer from moid and dn - eventually, this will be replaced something else
      # TODO: Ask the intersight people what the unique ID would look like.
      moid + "-" + dn
    end

    def physical_racks
      collector.physical_racks.each do |r|
        persister.physical_racks.build(
          :ems_ref => r.registered_device.moid,
          :name    => "dummy" # TODO: Obtain the name of the physical rack.
        )
      end
    end


    def firmwares
      collector.firmware_inventory.each do |firmware|
        server = persister.physical_servers.lazy_find(firmware.registered_device.moid)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        hardware = persister.physical_server_hardwares.lazy_find(computer)
        temp = "dummy"
        persister.physical_server_firmwares.build(
          :resource => hardware,
          :build    => firmware.type,  #  firmware.SoftwareId,
          # TODO: Parse the data for firmware.component somewhere (find out where it sould go)
          # TODO: Change the value under :name so that the value will actually resemble name and that name will be unique for every moid
          :name     => firmware.version, # for every device moid, there has to be unique name. For now, setting it to firmware.version
          :version  => firmware.version # firmware.Version
        )
      end
    end


  end
end
