module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_servers_details
      physical_racks
      hardwares
      # firmwares
    end 

    def physical_servers
      collector.physical_servers.each do |s|
        moid = s.registered_device.moid
        device_registration = collector.get_asset_device_registration_by_moid(moid)        
        rack = persister.physical_racks.lazy_find(moid)
        # Since there is no data about the chassis on the Intersight side, I cannot obtain the data about the chassis. Setting its value to nil
        chassis = nil
        # TODO: Obtain the data about health state, hostname
        server = persister.physical_servers.build(
          :ems_ref                => moid,
       	  :health_state           => "still to be found",  
          :hostname               => device_registration.device_hostname[0], # I assume one registered device manages one (and only one) compute element
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
        moid = s.registered_device.moid
        server = persister.physical_servers.lazy_find(moid)
        temp = "dummy"
        rack_unit = collector.get_rack_unit_from_physical_summary_moid(moid)
        locator_led_unit = collector.get_equipment_locator_led_by_moid(rack_unit.locator_led.moid)

        # TODO: Go through the data about the servers and obtain the data about the atributes, which at the moment hold value temp.
       	persister.physical_server_details.build(
       	  :description        => "no description", # TODO: Look for description method in endpoint "IntersightClient::CapabilityApi" when you open the second lab.
      	  :location_led_state        => locator_led_unit.oper_state, # find through rack_unit
      	  :machine_type        => temp, # TODO: Look at redfish for example of machine type
      	  :manufacturer        => temp, # no manufacturer given; look again through physical_summary_list
      	  :model        => s.model,
      	  :product_name        => s.name,
      	  :rack_name        => s.server_id,
      	  :resource        => server,
          :room        => s.slot_id,
          :serial_number        => s.serial,
        )
      end
    end


    def hardwares
      collector.physical_servers.each do |s|
        rack_unit = collector.get_rack_unit_from_physical_summary_moid(s.registered_device.moid)
        server = persister.physical_servers.lazy_find(s.registered_device.moid)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        board_unit = collector.get_compute_board_by_moid(rack_unit.board.moid)
        storage_controllers_list = board_unit.storage_controllers
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => board_unit.processors.count, # board.processors is an array with referenced processor as each element (and .count is the length operator)
          :disk_capacity   => "Still a TO-DO", # TODO: storage_controller.physical_disks is an array with physical disks. Out of it, obtain disk_capacity and memory_mb
          :memory_mb       => s.available_memory,
          :cpu_speed       => s.cpu_capacity,
       	  :disk_free_space => "Still a TO-DO" # TODO: Find info about disk_free_space. Haven't found it yet, but I assume it must be somewhere inside board_unit and/or storage_controllers
        )

        rack_unit.adapters.each do |adapter|
          adapter_unit = collector.get_adapter_unit_by_moid(adapter.moid)
          management_controller_unit = collector.get_management_controller_by_moid(adapter_unit.controller.moid)
          adapter_unit_dn = s.dn + "/" + "network-adapter-" + adapter_unit.adapter_id # TODO: Write this into a helper function
          persister.physical_server_network_devices.build(
            :hardware     => hardware,
            # TODO: Put forming the device name into a function
            :device_name  => adapter_unit_dn, # This is the way to write distinguished names for network adapters
            # TODO (tjazsch): Change the device type => "ethernet" to the actual device_type - minor problems with MiQ core implementation
            :device_type  => "ethernet", # TODO: Change the hardcoded "ethernet to the actual device_type - not sure, but I think this isn't the only device type present
            :manufacturer => "unknown", # TODO: Look at controller.model - depending if it contains inter or cisco, set its value accordingly
            :model        => management_controller_unit.model,
            # TODO: Ask Ales to ask the Intersight people how should we encode unique identifyer
            # (Since there's only unique ID of the single device and not for example, distinguished ID of physical_racks and physical_summary)
            :uid_ems      => adapter_unit.registered_device.moid + "-" + adapter_unit_dn # adapter_unit_dn is here only temporarily
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
          # TODO: r.dn instead of the "dummy"
          :name    => "dummy"
        )
      end
    end

<<-DOC
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
DOC
  end
end
