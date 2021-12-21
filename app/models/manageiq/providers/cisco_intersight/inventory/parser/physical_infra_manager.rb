module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_servers_details
      # firmwares
      physical_racks
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

    def firmwares
      collector.firmware_inventory.each do |firmware|
        persister.physical_server_firmwares.build(
          :resource => nil,
     	  :build => "dummy",
     	  :name => "dummy",
     	  :version => firmware.version
        )
      end
    end

    def physical_racks
      collector.physical_racks.each do |r|
        persister.physical_racks.build(
          :ems_ref => r.registered_device.moid,
          :name    => "dummy"
        )
      end
    end


    def physical_chassis
      collector.physical_chassis.each do |c|
        # parent_id = c.dig("Links", "ContainedBy", "@odata.id")
        # chassis = persister.physical_chassis.lazy_find(parent_id) if parent_id
        # rack = persister.physical_racks.lazy_find(parent_id) if parent_id

        persister.physical_chassis.build(
          :ems_ref                 => c["@odata.id"],
          :health_state            => c.Status.Health,
          :name                    => resource_name(c),
          :parent_physical_chassis => chassis,
          :physical_rack           => rack,
        )
      end
    end


  end
end
