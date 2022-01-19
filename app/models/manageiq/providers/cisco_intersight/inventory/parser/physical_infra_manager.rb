module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_server_details
      # physical_racks
      hardwares
      firmwares
    end

    def physical_servers
      collector.compute_blades.each do |s|
        registered_device_moid = get_registered_device_moid(s)
        device_registration = collector.get_asset_device_registration_by_moid(registered_device_moid)
        # Setting value of chassis and rack to nil for now
        chassis = nil # TODO: After chassis gets written into the DB, obtain it and write it here as reference using lazy find.
        rack = nil # TODO: After chassis gets written into the DB, obtain it and write it here as reference using lazy find.
        server = persister.physical_servers.build(
          :ems_ref => s.moid,
          :health_state => nil, # this piece of data is un-parsable until attribute 'health_state' is seen in ComputeBlade object
          # :health_state => get_health_state(s), # health_state obtained through atribute s.alarm_summary
          :hostname => device_registration.device_hostname[0], # I assume one registered device manages one (and only one) compute element
          # :name => s.name, (tjazsch): not setting its value for now. Later, I'll focus on this issue later
          :physical_chassis => chassis, # nil for now
          :physical_rack => rack, # nil for now
          :power_state => nil, # this piece of data is un-parsable until attribute 'oper_power_state' is seen in ComputeBlade object
          :raw_power_state => nil, # this piece of data is un-parsable until attribute 'admin_power_state' is seen in ComputeBlade object
          # :power_state => s.oper_power_state,
          # :raw_power_state => s.admin_power_state,
          :type => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
        )
        persister.physical_server_computer_systems.build(
          :managed_entity => server
        )
      end
    end

    def physical_server_details
      # Comment: description may be added if needed (through endpoint: AssetApi, class: AssetDeviceContractInformation)
      collector.compute_blades.each do |s|
        registered_device_moid = get_registered_device_moid(s)
        server = persister.physical_servers.lazy_find(s.moid)
        locator_led_unit = collector.get_equipment_locator_led_by_moid(s.locator_led.moid)
        device_contract_information_unit = collector.get_device_contract_information_from_device_moid(registered_device_moid)
        persister.physical_server_details.build(
          :description => device_contract_information_unit.product.description,
          :location => format_location(device_contract_information_unit),
          :location_led_state => get_locator_led_state(s),
          :machine_type => device_contract_information_unit.device_type,
          # :model => s.model,
          :model => nil,   # this piece of data is un-parsable until attribute 'model' is seen in ComputeBlade object
          # :product_name => s.name, (tjazsch): not setting its value for now. Later, I'll focus on this issue later
          :resource => server,
          :room => s.slot_id,
          # :serial_number => s.serial,
          :serial_number => nil  # this piece of data is un-parsable until attribute 'serial' is seen in ComputeBlade object
        )
      end
    end

    def hardwares
      collector.compute_blades.each do |s|
        # rack_unit = collector.get_rack_unit_from_physical_summary_moid(s.registered_device.moid)
        server = persister.physical_servers.lazy_find(s.moid)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        board_unit = collector.get_compute_board_by_moid(s.board.moid)
        storage_controllers_list = board_unit.storage_controllers
        # disk_capacity and disk_free_space aren't finished yet. Setting their value to -1
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => nil, # this piece of daxta is un-parsable until attribute 'num_cpu_cores' is seen in ComputeBlade object
          # :cpu_total_cores => s.num_cpu_cores, # board.processors is an array with referenced processor as each element (and .count is the length operator)
          :disk_capacity => -1, # TODO: storage_controller.physical_disks is an array with physical disks. Out of it, obtain disk_capacity and memory_mb
          :memory_mb => nil, # this piece of data is un-parsable until attribute 'available_memory' is seen in ComputeBlade object
          # :memory_mb => s.available_memory,
          # :cpu_speed => s.cpu_capacity, (tjazsch): not setting its value for now. Later, I'll focus on this issue later
          :disk_free_space => -1 # TODO: Find info about disk_free_space. Haven't found it yet, but I assume it must be somewhere inside board_unit and/or storage_controllers
        )

        s.adapters.each do |adapter|
          adapter_unit = collector.get_adapter_unit_by_moid(adapter.moid)
          management_controller_unit = collector.get_management_controller_by_moid(adapter_unit.controller.moid)
          persister.physical_server_network_devices.build(
            :hardware => hardware,
            # :device_name => s.name, (tjazsch): not setting its value for now. Later, I'll focus on this issue later
            :device_type => "ethernet",
            :manufacturer => get_manufacturer_from_management_controller(management_controller_unit),
            :model => management_controller_unit.model,
            :uid_ems => adapter_unit.moid
          )
        end

        storage_controllers_list.each do |storage_controller_reference|
          persister.physical_server_storage_adapters.build(
            :hardware => hardware,
            # :device_name => s.name, (tjazsch): not setting its value for now. Later, I'll focus on this issue later
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
      collector.firmware_inventory.each do |firmware_summary|
        firmware_summary.components_fw_inventory.each do |component_fw_inventory|
          server = persister.physical_servers.lazy_find(firmware_summary.server.moid)
          computer = persister.physical_server_computer_systems.lazy_find(server)
          hardware = persister.physical_server_hardwares.lazy_find(computer)
          persister.physical_server_firmwares.build(
            :resource => hardware,
            :build => component_fw_inventory.label,
            :name => component_fw_inventory.label,
            :version => component_fw_inventory.version
          )
        end
      end
    end

    def get_health_state(server)
      alarm_summary = server.alarm_summary
      if alarm_summary.critical > 0
        health = "Critical"
      elsif alarm_summary.warning > 0
        health = "Warning"
      else
        health = "Valid"
      end
      health
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

    def format_location(device_contract_information_object)
      shipping_info = device_contract_information_object.product.ship_to
      [
        shipping_info.name,
        shipping_info.address1,
        shipping_info.postal_code,
        shipping_info.postal_code,
        shipping_info.city,
        shipping_info.country
      ].join(", ")
    end

    def get_locator_led_state(object)
      # object represents either ComputeBlade or EquipmentChassis type objects, that are given as response from the client
      if object.locator_led
        collector.get_equipment_locator_led_by_moid(object.locator_led.moid).oper_state
      else
        nil
      end
    end


  end
end
