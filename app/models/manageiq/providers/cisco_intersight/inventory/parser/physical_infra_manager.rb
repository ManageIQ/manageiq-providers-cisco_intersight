module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_server_details
      physical_racks
      hardwares
      firmwares
      physical_chassis
      physical_chassis_details
    end

    def physical_servers
      collector.physical_servers.each do |s|
        registered_device_moid = get_registered_device_moid(s)
        device_registration = collector.get_asset_device_registration_by_moid(registered_device_moid)
        # Setting value of chassis and rack to nil for now
        chassis = nil # TODO: After chassis gets written into the DB, obtain it and write it here as reference using lazy find.
        rack = nil # TODO: After chassis gets written into the DB, obtain it and write it here as reference using lazy find.
        server = persister.physical_servers.build(
          :ems_ref          => s.moid,
          :health_state     => get_health_state(s), # health_state obtained through atribute s.alarm_summary
          :hostname         => device_registration.device_hostname[0], # I assume one registered device manages one (and only one) compute element
          :name             => s.name,
          :physical_chassis => chassis, # nil for now
          :physical_rack    => rack, # nil for now
          :power_state      => s.oper_power_state,
          :raw_power_state  => s.admin_power_state,
          :type => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
        )
        persister.physical_server_computer_systems.build(
          :managed_entity => server
        )
      end
    end

    def physical_server_details
      collector.physical_servers.each do |s|
        registered_device_moid = get_registered_device_moid(s)
        server = persister.physical_servers.lazy_find(s.moid)
        source_object = collector.get_source_object_from_physical_server(s)
        device_contract_information_unit = collector.get_device_contract_information_from_device_moid(registered_device_moid)
        persister.physical_server_details.build(
          :description        => device_contract_information_unit.product.description,
          :location           => format_location(device_contract_information_unit),
          :location_led_state => get_locator_led_state(source_object),
          :machine_type       => device_contract_information_unit.device_type,
          :model              => s.model,
          :product_name       => s.name,
          :resource           => server,
          :room               => s.slot_id,
          :serial_number      => s.serial,
        )
      end
    end

    def hardwares
      collector.physical_servers.each do |s|
        server = persister.physical_servers.lazy_find(s.moid)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        source_object = collector.get_source_object_from_physical_server(s)
        board_unit = collector.get_compute_board_by_moid(source_object.board.moid)
        storage_controllers_list = board_unit.storage_controllers
        # disk_capacity and disk_free_space aren't finished yet. Setting their value to -1
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => s.num_cpu_cores,
          :memory_mb       => s.available_memory,
          :cpu_speed       => s.cpu_capacity,
        )

        source_object.adapters.each do |adapter|
          adapter_unit = collector.get_adapter_unit_by_moid(adapter.moid)
          management_controller_unit = collector.get_management_controller_by_moid(adapter_unit.controller.moid)
          persister.physical_server_network_devices.build(
            :hardware     => hardware,
            :device_name  => s.name,
            :device_type  => "ethernet",
            :manufacturer => get_manufacturer_from_management_controller(management_controller_unit),
            :model        => management_controller_unit.model,
            :uid_ems      => adapter_unit.moid
          )
        end

        storage_controllers_list.each do |storage_controller_reference|
          persister.physical_server_storage_adapters.build(
            :hardware    => hardware,
            :device_name => s.name,
            :device_type => "storage",
            :uid_ems     => storage_controller_reference.moid
          )
        end
      end
    end

    def physical_racks
      collector.physical_racks.each do |r|
        # No data about the physical_racks yet, so I cannot parse the data about it.
        persister.physical_racks.build(
          :ems_ref => r.registered_device.moid,
          :name    => ""
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
            :build    => component_fw_inventory.label,
            :name     => component_fw_inventory.label,
            :version  => component_fw_inventory.version
          )
        end
      end
    end

    def physical_chassis
      collector.physical_chassis.each do |c|
        persister.physical_chassis.build(
          :ems_ref      => c.moid,
          :health_state => get_health_state(c),
          :name         => c.name
        )
      end
    end

    def physical_chassis_details
      collector.physical_chassis.each do |c|
        registered_device_moid = get_registered_device_moid(c)
        device_contract_information_unit = collector.get_device_contract_information_from_device_moid(registered_device_moid)
        chassis = persister.physical_chassis.lazy_find(c.moid)
        persister.physical_chassis_details.build(
          :description        => device_contract_information_unit.product.description,
          :location           => format_location(device_contract_information_unit),
          :location_led_state => get_locator_led_state(c),
          :model              => c.model,
          :part_number        => c.part_number,
          :resource           => chassis,
          :serial_number      => c.serial
        )
      end
    end


    def get_health_state(object)
      alarm_summary = object.alarm_summary
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
