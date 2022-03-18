module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
      physical_server_details
      # physical_racks This function isn't ready yet.
      server_hardware
      firmwares
      physical_chassis
      physical_chassis_details
      physical_switches
      physical_switch_details
      switch_hardware
      physical_switch_network_ports
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
          :power_state      => s.admin_power_state,
          :raw_power_state  => s.admin_power_state,
          :manufacturer     => s.vendor,
          :type             => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer"
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
          :description        => get_product_description(device_contract_information_unit),
          :location           => format_location(device_contract_information_unit),
          :location_led_state => get_locator_led_state(source_object),
          :machine_type       => get_machine_type(device_contract_information_unit),
          :model              => s.model,
          :product_name       => get_product_name(device_contract_information_unit),
          :resource           => server,
          :room               => s.slot_id,
          :serial_number      => s.serial
        )
      end
    end

    def physical_switches
      collector.network_elements.each do |network_element|
        persister.physical_switches.build(
          :name         => network_element.dn,
          :uid_ems      => network_element.moid,
          :switch_uuid  => network_element.moid,
          :health_state => get_health_state(network_element),
          :type         => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitch"
        )
      end
    end

    def physical_switch_details
      collector.network_elements.each do |network_element|
        registered_device_moid = get_registered_device_moid(network_element)
        switch = persister.physical_switches.lazy_find(network_element.moid)
        device_contract_information_unit = collector.get_device_contract_information_from_device_moid(registered_device_moid)
        persister.physical_switch_details.build(
          :description   => get_product_description(device_contract_information_unit),
          :location      => format_location(device_contract_information_unit),
          :resource      => switch,
          :product_name  => get_product_name(device_contract_information_unit),
          :serial_number => network_element.serial,
          :manufacturer  => network_element.vendor,
          :model         => network_element.model,
          :machine_type  => get_machine_type(device_contract_information_unit)
        )
      end
    end

    def server_hardware
      collector.physical_servers.each do |s|
        server = persister.physical_servers.lazy_find(s.moid)
        computer = persister.physical_server_computer_systems.lazy_find(server)
        source_object = collector.get_source_object_from_physical_server(s)
        board_unit = collector.get_compute_board_by_moid(source_object.board.moid)
        storage_controllers_list = board_unit.storage_controllers
        hardware = persister.physical_server_hardwares.build(
          :computer_system => computer,
          :cpu_total_cores => s.num_cpu_cores,
          :memory_mb       => s.available_memory,
          :cpu_speed       => s.cpu_capacity
        )

        source_object.adapters.each do |adapter|
          adapter_unit = collector.get_adapter_unit_by_moid(adapter.moid)
          persister.physical_server_network_devices.build(
            :hardware     => hardware,
            :device_name  => adapter_unit.adapter_id,
            :device_type  => "ethernet",
            :manufacturer => adapter_unit.vendor,
            :model        => adapter_unit.model,
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

    def switch_hardware
      collector.network_elements.each do |network_element|
        physical_switch = persister.physical_switches.lazy_find(network_element.moid)
        hardware = persister.physical_switch_hardwares.build(
          :physical_switch => physical_switch,
          :memory_mb       => network_element.available_memory
        )

        persister.physical_switch_networks.build(
          :hardware        => hardware,
          :ipaddress       => network_element.out_of_band_ip_address,
          :subnet_mask     => network_element.out_of_band_ip_mask,
          :ipv6address     => network_element.out_of_band_ipv6_address,
          :default_gateway => network_element.out_of_band_ip_gateway
        )

        ucsm_running_firmware = get_ucsm_running_firmware(network_element)

        next unless ucsm_running_firmware

        persister.physical_switch_firmwares.build(
          :resource     => hardware,
          :build        => ucsm_running_firmware.package_version,
          :name         => ucsm_running_firmware.dn,
          :version      => ucsm_running_firmware.version,
          :release_date => ucsm_running_firmware.create_time
        )

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
          :description        => get_product_description(device_contract_information_unit),
          :location           => format_location(device_contract_information_unit),
          :location_led_state => get_locator_led_state(c),
          :model              => c.model,
          :part_number        => c.part_number,
          :resource           => chassis,
          :serial_number      => c.serial,
          :product_name       => get_product_name(device_contract_information_unit),
          :machine_type       => get_machine_type(device_contract_information_unit)
        )
      end
    end

    def physical_switch_network_ports
      collector.network_elements.each do |network_element|
        network_element.cards.each do |switch_card_reference|
          switch_card = collector.get_equipment_switch_card_by_moid(switch_card_reference.moid)
          switch_card.port_groups.each do |port_group_reference|
            port_group = collector.get_port_group_by_moid(port_group_reference.moid)
            port_group.ethernet_ports.each do |physical_port_reference|
              physical_port = collector.get_ether_physical_port_by_moid(physical_port_reference.moid)
              physical_switch = persister.physical_switches.lazy_find(network_element.moid)
              persister.physical_switch_network_ports.build(
                :physical_switch => physical_switch,
                :uid_ems         => physical_port.moid,
                :port_name       => physical_port.dn,
                :port_type       => "ethernet",
                :mac_address     => physical_port.mac_address,
                :port_index      => physical_port.port_id
              )
            end
          end
        end
      end
    end

    def get_health_state(object)
      alarm_summary = object.alarm_summary
      if alarm_summary.critical > 0
        "Critical"
      elsif alarm_summary.warning > 0
        "Warning"
      else
        "Valid"
      end
    end

    def get_registered_device_moid(intersight_api_object)
      intersight_api_object.registered_device.moid
    end

    def format_location(device_contract_information_object)
      address = device_contract_information_object.end_customer.address
      # Regex gsub(/\s+/, ' ') replaces multiple spaces with one. This happens if one of the elements
      # in the array is equal to empty string.
      [
        address.address1,
        address.address2,
        address.address3,
        address.city,
        address.country,
        address.county,
        address.location,
        address.name,
        address.postal_code,
        address.province,
        address.state
      ].join(" ").gsub(/\s+/, ' ')
    end

    def get_ucsm_running_firmware(network_element)
      # Helper method to method switch_hardwares
      # network_element is Intersight's object of class NetworkElement. Depending whether firmware is null or not,
      # returns object of class FirmwareRunningFirmware.
      if network_element.ucsm_running_firmware
        collector.get_firmware_running_firmware_by_moid(network_element.ucsm_running_firmware.moid)
      end
    end

    def get_locator_led_state(object)
      # object represents either ComputeBlade or EquipmentChassis type objects, that are given as response from the client
      if object.locator_led
        collector.get_equipment_locator_led_by_moid(object.locator_led.moid).oper_state
      end
    end

    def get_product_name(device_contract_information_unit)
      # Helper function :AssetDetails type of collections (functions with name ..._details)
      device_contract_information_unit.product.bill_to.name
    end

    def get_product_description(device_contract_information_unit)
      # Helper function :AssetDetails type of collections (functions with name ..._details)
      device_contract_information_unit.product.description
    end

    def get_machine_type(device_contract_information_unit)
      # Helper function :AssetDetails type of collections (functions with name ..._details)
      device_contract_information_unit.device_type
    end
  end
end
