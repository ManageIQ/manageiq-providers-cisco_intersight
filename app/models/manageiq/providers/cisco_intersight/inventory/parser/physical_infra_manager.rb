module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_servers_details
      # firmwares
      physical_racks
      hardwares
      # physical_server_network_devices
    end 

    def physical_servers
      collector.physical_servers.each do |s|
        
        # Temporarily setting the values of rack and chassis to nil - as the other two collections are built,
        # this is going to be changed by lazy_find function on the id
        rack = persister.physical_racks.lazy_find(s.device_mo_id)
        chassis = nil

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

    # def firmwares
    #   collector.firmware_inventory.each do |firmware|
    #     persister.physical_server_firmwares.build(
    #       :resource => nil,
    #  	  :build => "dummy",
    #  	  :name => "dummy",
    #  	  :version => firmware.version
    #     )
    #   end
    # end

    def hardwares
      collector.physical_servers.each do |s|
        server = persister.physical_servers.lazy_find(s.device_mo_id)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => s.num_cpus,
          :disk_capacity   => s.total_memory,
          :memory_mb       => 0, # TODO: Reformat total memory and write it to mb && replace 0 with that value
          :cpu_speed       => s.cpu_capacity,
       	  :disk_free_space => s.available_memory
        )

	adapters_current = collector.physical_server_network_devices.select { |c| c.registered_device.moid == s.registered_device.moid }

        (adapters_current || []).each  do |net_adapter|

          temp = net_adapter.registered_device.moid + "-" + net_adapter.dn

          persister.physical_server_network_devices.build(
       	    :hardware     => hardware,
       	    :device_name  => net_adapter.dn, # temp
       	    :device_type  => get_device_type3(net_adapter), # "ethernet", # temp, 
       	    :manufacturer => "unknown", # question: is the first word in the net_adapter.model the manufacturer? 
       	    :model        => net_adapter.model, # temp
            :uid_ems	  => temp # net_adapter.registered_device.moid # temp
          )
        end
      end
    end

    def get_device_type1(net_adapter)
      adapter_model = net_adapter.model
      if (adapter_model.include? "Ethernet") && (adapter_model.include? "Cisco")
        device_type = "ethernet cisco"
      elsif (adapter_model.include? "Controller") && (adapter_model.include? "Cisco")
        device_type = "controller cisco"
      elsif (adapter_model.include? "Ethernet") && (adapter_model.include? "Intel")
        device_type = "ethernet intel"
      elsif (adapter_model.include? "Controller") && (adapter_model.include? "Intel")
        device_type = "controller intel"
      else
        device_type = "unknown"
      end
      device_type
    end


    def get_device_type2(net_adapter)
      adapter_model = net_adapter.model
      if (adapter_model.include? "Ethernet")
        device_type = "ethernet"
      elsif (adapter_model.include? "Controller")
        device_type = "controller"
      else
	device_type = "unknown"
      end
      device_type
    end

    def get_device_type3(net_adapter)
      device_type = "ethernet"                     
      device_type
    end

    def physical_racks
      collector.physical_racks.each do |r|
        persister.physical_racks.build(
          :ems_ref => r.registered_device.moid,
          :name    => "dummy"
        )
      end
    end



  end
end
