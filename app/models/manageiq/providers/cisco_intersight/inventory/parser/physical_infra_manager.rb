module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_server_details
      physical_racks
      hardwares
      firmwares
    end

    def physical_servers
      collector.physical_servers.each do |s|
        moid = get_registered_device_moid(s)
        device_registration = collector.get_asset_device_registration_by_moid(moid)
        rack = persister.physical_racks.lazy_find(moid)
        # Since there is no data about the chassis on the Intersight side, I cannot obtain the data about the chassis.
        # Setting its value to nil for now.
        chassis = nil # TODO: After chassis gets written into the DB, obtain it and write it here as reference using lazy find.
        server = persister.physical_servers.build(
          :ems_ref => moid,
          :health_state => "still to be found", # TODO: Obtain the data about health state
          :hostname => device_registration.device_hostname[0], # I assume one registered device manages one (and only one) compute element
          :name => s.name,
          :physical_chassis => chassis,
          :physical_rack => rack,
          :power_state => s.admin_power_state,
          :raw_power_state => s.oper_power_state,
          :type => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
        )
        persister.physical_server_computer_systems.build(
          :managed_entity => server
        )
      end
    end

    def physical_server_details
      collector.physical_servers.each do |s|
        moid = get_registered_device_moid(s)
        server = persister.physical_servers.lazy_find(moid)
        rack_unit = collector.get_rack_unit_from_physical_summary_moid(moid)
        locator_led_unit = collector.get_equipment_locator_led_by_moid(rack_unit.locator_led.moid)
        persister.physical_server_details.build(
          :location_led_state => locator_led_unit.oper_state,
          :model => s.model,
          :product_name => s.name,
          :rack_name => s.server_id,
          :resource => server,
          :room => s.slot_id,
          :serial_number => s.serial,
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
        # disk_capacity and disk_free_space aren't finished yet. Setting their value to -1
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => board_unit.processors.count, # board.processors is an array with referenced processor as each element (and .count is the length operator)
          :disk_capacity => -1, # TODO: storage_controller.physical_disks is an array with physical disks. Out of it, obtain disk_capacity and memory_mb
          :memory_mb => s.available_memory,
          :cpu_speed => s.cpu_capacity,
          :disk_free_space => -1 # TODO: Find info about disk_free_space. Haven't found it yet, but I assume it must be somewhere inside board_unit and/or storage_controllers
        )

        rack_unit.adapters.each do |adapter|
          adapter_unit = collector.get_adapter_unit_by_moid(adapter.moid)
          management_controller_unit = collector.get_management_controller_by_moid(adapter_unit.controller.moid)
          adapter_unit_dn = get_adapter_unit_dn(s, adapter_unit)
          persister.physical_server_network_devices.build(
            :hardware => hardware,
            :device_name => s.name, # Note that this is name of the entire device, not only the name of network adapter
            :device_type => "ethernet",
            :manufacturer => get_manufacturer_from_management_controller(management_controller_unit),
            :model => management_controller_unit.model,
            # TODO: Ask Ales to ask the Intersight people how should we encode unique identifyer
            # (Since there's only unique ID of the single device and not for example, distinguished ID of physical_racks and physical_summary)
            # TODO: Replace this uid_ems with some "ID" (after we find out, how we should set it).
            :uid_ems => get_temporary_unique_identifyer(adapter_unit.registered_device.moid, adapter_unit_dn)
          )
        end

        storage_controllers_list.each do |storage_controller_reference|
          persister.physical_server_storage_adapters.build(
            :hardware => hardware,
            :device_name => s.name, # Note that this is name of the entire device, not only the name of storage controller
            :device_type => "storage",
            :uid_ems => storage_controller_reference.moid
          )
        end
      end
    end

    def physical_racks
      collector.physical_racks.each do |r|
        persister.physical_racks.build(
          :ems_ref => r.registered_device.moid,
          # TODO: r.dn instead of the "dummy"
          :name => "to-be-done"
        )
      end
    end

    def firmwares
      collector.firmware_inventory.each do |firmware|
        server = persister.physical_servers.lazy_find(firmware.registered_device.moid)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        hardware = persister.physical_server_hardwares.lazy_find(computer)
        persister.physical_server_firmwares.build(
          :resource => hardware,
          :build => firmware.component,
          :name => firmware.type + " - " + firmware.version, # for every device moid, there has to be unique name. For now, setting it to firmware.version
          :version => firmware.version
        )
      end
    end

    def get_adapter_unit_dn(server, adapter_unit)
      server.dn + "/" + "network-adapter-" + adapter_unit.adapter_id
    end

    def get_manufacturer_from_management_controller(management_controller_unit)
      model = management_controller_unit.model
      if (model.include? "Cisco") or (model.include? "cisco")
        manufacturer = "Cisco"
      elsif (model.include? "Intel") or (model.include? "intel")
        manufacturer = "Intel"
      else
        manufacturer = "unknown"
      end
      manufacturer
    end

    # This will get removed after proper moid encoding is set up for adaters.
    def get_temporary_unique_identifyer(moid, dn)
      moid + "-" + dn
    end

    def get_registered_device_moid(intersight_api_object)
      intersight_api_object.registered_device.moid
    end

  end
end
