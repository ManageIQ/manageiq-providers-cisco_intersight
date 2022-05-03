module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser
    def parse
      physical_servers
      physical_racks
      physical_chassis
      physical_server_profiles
      physical_switches
    end

    # Methods that are executed during refresh call

    def physical_servers
      # Parsing active servers:
      collector.physical_servers.each do |server|
        # build collection physical_servers
        physical_server = build_physical_server(server)
        # build collection physical_server_details
        build_physical_server_details(physical_server, server)
        # build collection physical_server_computer_systems
        physical_server_computer_system = build_physical_server_computer_system(physical_server)

        # Since Intersight's source object is only consolidated view of either object ComputePhysicalSummary of ComputeRackUnit,
        # source object has to be obtained. I store it onto source_object
        source_object = collector.get_source_object_from_physical_server(server)
        board_unit = collector.get_compute_board_by_moid(source_object&.board&.moid) if source_object&.board&.moid
        # storage_controllers_list is only a list of references to the storage controllers, but not list of intersight's
        # storage controllers itself
        storage_controllers_list = board_unit.storage_controllers if board_unit
        # build collection physical_server_hardwares
        hardware = build_physical_server_hardwares(physical_server_computer_system, server)

        source_object.adapters.each do |adapter|
          adapter_unit = collector.get_adapter_unit_by_moid(adapter.moid)
          # build collection physical_server_network_devices
          build_physical_server_network_devices(hardware, adapter_unit)
        end

        storage_controllers_list&.each do |storage_controller_reference|
          # build collection physical_server_storage_adapters
          build_physical_server_storage_adapters(hardware, storage_controller_reference)
        end

        physical_server_management_device = build_physical_server_management_devices(hardware, server)
        build_physical_server_networks(physical_server_management_device, server)

        firmware_firmware_summary = collector.firmware_firmware_summary_by_moid[server.moid]
        next unless firmware_firmware_summary

        firmware_firmware_summary.components_fw_inventory.each do |component_fw_inventory|
          # build collection physical_server_firmwares
          build_physical_server_firmwares(hardware, component_fw_inventory)
        end
      end

      # Parsing decomissioned servers:
      collector.decomissioned_servers.each do |s|
        build_decomissioned_physical_infrastructure(s)
      end
    end

    def physical_racks
      collector.physical_racks.each do |r|
        # No data about the physical_racks yet, so I cannot parse the data about it (explained inside function below).
        build_physical_racks(r)
      end
    end

    def physical_chassis
      collector.physical_chassis.each do |c|
        # build collection physical_chassis
        build_physical_chassis(c)
        # build collection physical_chassis_details
        build_physical_chassis_details(c)
      end
    end

    def physical_switches
      collector.network_elements.each do |network_element|
        # object network_element_summary has the same moid as network_element.
        # network_element_summary is needed to obtain info about switch's name
        network_element_summary = collector.get_network_element_summary_by_moid(network_element.moid)
        # build collection physical_switches
        build_physical_switches(network_element, network_element_summary)
        # build collection physical_switch_details
        build_physical_switch_details(network_element)
        # build collection physical_switch_hardwares
        hardware = build_physical_switch_hardwares(network_element)
        # build collection physical_switch_networks
        build_physical_switch_networks(hardware, network_element)
        # build collection physical_switch_network_ports
        # Note that for every networking element (fabric interconnect) there may be (and probably are) multiple network ports.
        build_physical_switch_network_ports(network_element)
        # If there's data about the running firmware, build collection build_physical_switch_firmwares
        ucsm_running_firmware = get_ucsm_running_firmware(network_element)
        next unless ucsm_running_firmware

        build_physical_switch_firmwares(hardware, ucsm_running_firmware)
      end
    end

    def physical_server_profiles
      collector.physical_server_profiles.each do |c|
        # build collection physical_server_profiles
        build_physical_server_profiles(c)
      end
    end

    private

    # Methods that directly build out inventory collections

    def build_physical_chassis(chassis)
      # Builds out collection physical_chassis
      # Object types:
      #   - chassis - EquipmentChassis, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalChassis
      persister.physical_chassis.build(
        :ems_ref      => chassis.moid,
        :health_state => get_health_state(chassis),
        :name         => chassis.name
      )
    end

    def build_physical_chassis_details(chassis)
      # Builds out collection physical_chassis
      # Object types:
      #   - chassis - EquipmentChassis, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::AssetDetails
      physical_chassis = persister.physical_chassis.lazy_find(chassis.moid)
      registered_device_moid = get_registered_device_moid(chassis)
      device_contract_information_unit = collector.device_contract_informations_by_moid[registered_device_moid]
      persister.physical_chassis_details.build(
        :description        => get_product_description(device_contract_information_unit),
        :location           => format_location(device_contract_information_unit),
        :location_led_state => get_locator_led_state(chassis),
        :model              => chassis.model,
        :part_number        => chassis.part_number,
        :resource           => physical_chassis,
        :serial_number      => chassis.serial,
        :product_name       => get_product_name(device_contract_information_unit),
        :machine_type       => get_machine_type(device_contract_information_unit)
      )
    end

    def build_physical_racks(rack)
      # Was not able to test it yet due to not having physical racks written on the intersight side with the current lab rights
      # TODO: Find out which API call should be used here (after racks are viewable on the API viewer).
      # Builds out collection physical_racks
      # Object types:
      #   - rack - <I don't know yet>, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalChassis

      persister.physical_racks.build(
        :ems_ref => rack.moid,
        :name    => ""
      )
    end

    def build_physical_server(server)
      # Builds out collection physical_servers
      # Object types:
      #   - server - ComputePhysicalSummary, object obtained by intersight client
      #   - physical_rack - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalRacks
      #   - physical_chassis - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalChassis
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServers

      # Obtain data about chassis and racks if they're wired to the server
      physical_rack = nil # TODO: After chassis gets written into the DB, obtain it and write it here as reference using lazy find.
      physical_chassis = if server&.parent&.object_type == "equipment.Chassis"
                           persister.physical_chassis.lazy_find(server&.parent&.moid)
                         end
      registered_device_moid = get_registered_device_moid(server)
      device_registration = collector.get_asset_device_registration_by_moid(registered_device_moid)
      persister.physical_servers.build(
        :ems_ref          => server.moid,
        :health_state     => get_health_state(server), # health_state obtained through atribute s.alarm_summary
        :hostname         => device_registration.device_hostname[0], # I assume one registered device manages one (and only one) compute element
        :name             => server.name,
        :physical_chassis => physical_chassis,
        :physical_rack    => physical_rack, # nil for now
        :power_state      => server.oper_power_state,
        :raw_power_state  => server.oper_power_state,
        :manufacturer     => server.vendor
      )
    end

    def build_physical_server_details(physical_server, server)
      # Builds out collection physical_server_details
      # Object types:
      #   - physical_server - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServers
      #   - server - ComputePhysicalSummary, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::AssetDetails
      registered_device_moid = get_registered_device_moid(server)
      source_object = collector.get_source_object_from_physical_server(server)
      device_contract_information_unit = collector.device_contract_informations_by_moid[registered_device_moid]
      persister.physical_server_details.build(
        :description        => get_product_description(device_contract_information_unit),
        :location           => format_location(device_contract_information_unit),
        :location_led_state => get_locator_led_state(source_object),
        :machine_type       => get_machine_type(device_contract_information_unit),
        :model              => server.model,
        :product_name       => get_product_name(device_contract_information_unit),
        :resource           => physical_server,
        :room               => server.slot_id,
        :serial_number      => server.serial
      )
    end

    def build_physical_server_computer_system(physical_server)
      # Builds out collection physical_server_computer_systems
      # Object types:
      #   - physical_server - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServers
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerComputerSystems
      persister.physical_server_computer_systems.build(
        :managed_entity => physical_server
      )
    end

    def build_physical_server_hardwares(computer_system, server)
      # Builds out collection physical_server_hardwares
      # Object types:
      #   - computer_system - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerComputerSystems
      #   - server - ComputePhysicalSummary, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerHardwares
      persister.physical_server_hardwares.build(
        :computer_system => computer_system,
        :cpu_total_cores => server.num_cpu_cores,
        :memory_mb       => server.available_memory,
        :cpu_speed       => server.cpu_capacity
      )
    end

    def build_physical_server_network_devices(physical_server_hardware, adapter_unit)
      # Builds out collection physical_server_network_devices
      # Object types:
      #   - computer_system - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerHardwares
      #   - adapter_unit - AdapterUnit, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerNetworkDevices
      persister.physical_server_network_devices.build(
        :hardware     => physical_server_hardware,
        :device_name  => adapter_unit.adapter_id,
        :device_type  => "ethernet",
        :manufacturer => adapter_unit.vendor,
        :model        => adapter_unit.model,
        :uid_ems      => adapter_unit.moid
      )
    end

    def build_physical_server_storage_adapters(physical_server_hardware, storage_controller_ref)
      # TODO: replace controller refererence with an actual one.
      # Builds out collection physical_server_storage_adapters
      # Object types:
      #   - physical_server_hardware - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerHardwares
      #   - storage_controller - StorageController, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerNetworkDevices
      persister.physical_server_storage_adapters.build(
        :hardware    => physical_server_hardware,
        # :device_name => s.name, TODO: Find the device name of the storage adapter
        :device_type => "storage",
        :uid_ems     => storage_controller_ref.moid
      )
    end

    def build_physical_server_firmwares(physical_server_hardware, component_fw_inventory)
      # Builds out collection physical_server_firmwares
      # Object types:
      #   - physical_server_hardware - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerHardwares
      #   - component_fw_inventory - FirmwareFirmwareSummary, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerFirmwares
      persister.physical_server_firmwares.build(
        :resource => physical_server_hardware,
        :build    => component_fw_inventory.label,
        :name     => component_fw_inventory.label,
        :version  => component_fw_inventory.version
      )
    end

    def build_physical_server_management_devices(physical_server_hardware, server)
      # Builds out collection physical_server_details
      # Object types:
      #   - physical_server_hardware - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerHardwares
      #   - server - ComputePhysicalSummary, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerManagementDevices
      persister.physical_server_management_devices.build(
        :hardware    => physical_server_hardware,
        :address     => server.mgmt_ip_address,
        :device_type => 'management'
      )
    end

    def build_physical_server_networks(physical_server_management_device, server)
      # Builds out collection physical_server_details
      # Object types:
      #   - physical_server_hardware - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerManagementDevices
      #   - server - ComputePhysicalSummary, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerNetworks

      # There's still missing data for ipv4address
      persister.physical_server_networks.build(
        :guest_device => physical_server_management_device,
        :ipaddress    => server.mgmt_ip_address,
        :ipv6address  => "" # So far, there hasn't been any data regarding ipv6 address for physical servers
      )
    end

    def build_physical_switches(network_element, network_element_summary)
      # Builds out collection physical_switches
      # Object types:
      #   - network_element - NetworkElements, object obtained by intersight client
      #   - network_element_summary - NetworkElementSummary, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitches
      persister.physical_switches.build(
        :name         => network_element_summary.name,
        :uid_ems      => network_element.moid,
        :switch_uuid  => network_element.moid,
        :health_state => get_health_state(network_element)
      )
    end

    def build_physical_switch_details(network_element)
      # Builds out collection physical_switches
      # Object types:
      #   - network_element - NetworkElements, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::AssetDetails
      registered_device_moid = get_registered_device_moid(network_element)
      switch = persister.physical_switches.lazy_find(network_element.moid)
      device_contract_information_unit = collector.device_contract_informations_by_moid[registered_device_moid]
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

    def build_physical_switch_hardwares(network_element)
      # Builds out collection physical_switches
      # Object types:
      #   - network_element - NetworkElements, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitchHardwares
      physical_switch = persister.physical_switches.lazy_find(network_element.moid)
      persister.physical_switch_hardwares.build(
        :physical_switch => physical_switch,
        :memory_mb       => network_element.available_memory
      )
    end

    def build_physical_switch_networks(physical_switch_hardware, network_element)
      # Builds out collection physical_switches
      # Object types:
      #   - network_element - NetworkElements, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitchNetworks
      persister.physical_switch_networks.build(
        :hardware        => physical_switch_hardware,
        :ipaddress       => network_element.out_of_band_ip_address,
        :subnet_mask     => network_element.out_of_band_ip_mask,
        :ipv6address     => network_element.out_of_band_ipv6_address,
        :default_gateway => network_element.out_of_band_ip_gateway
      )
    end

    def build_physical_switch_firmwares(physical_switch_hardware, firmware_running_firmware)
      # Builds out collection physical_switch_firmwares
      # Object types:
      #   - firmware_running_firmware - FirmwareRunningFirmware, object obtained by intersight client
      #   - physical_switch_hardware - ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitchHardwares
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalSwitchFirmwares
      persister.physical_switch_firmwares.build(
        :resource     => physical_switch_hardware,
        :build        => firmware_running_firmware.package_version,
        :name         => firmware_running_firmware.dn,
        :version      => firmware_running_firmware.version,
        :release_date => firmware_running_firmware.create_time
      )
    end

    def build_physical_switch_network_ports(network_element)
      # Parses and stores all physical switch network ports for the specific networking element (Fabric interconnect)
      network_element.cards.each do |switch_card_reference|
        switch_card = collector.get_equipment_switch_card_by_moid(switch_card_reference.moid)
        switch_card.port_groups.each do |port_group_reference|
          port_group = collector.get_port_group_by_moid(port_group_reference.moid)
          port_group.ethernet_ports.each do |physical_port_reference|
            physical_port = collector.get_ether_physical_port_by_moid(physical_port_reference.moid)
            physical_switch = persister.physical_switches.lazy_find(network_element.moid)
            persister.physical_switch_network_ports.build(
              :physical_switch    => physical_switch,
              :uid_ems            => physical_port.moid,
              :port_name          => physical_port.dn,
              :port_type          => "ethernet",
              :mac_address        => physical_port.mac_address,
              :port_index         => physical_port.port_id,
              :connected_port_uid => physical_port.moid
            )
          end
        end
      end
    end

    def build_decomissioned_physical_infrastructure(server)
      # Builds out collections physical_servers, physical_server_details, physical_server_computer_systems and
      # physical_server_hardwares for decomissioned servers
      # Object types:
      #   - server - SearchSearchItem, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer
      physical_server = persister.physical_servers.build(
        :ems_ref         => server.moid,
        :power_state     => "decomissioned",
        :raw_power_state => "decomissioned"
      )

      computer = persister.physical_server_computer_systems.build(
        :managed_entity => physical_server
      )

      persister.physical_server_details.build(
        :resource => physical_server
      )

      persister.physical_server_hardwares.build(
        :computer_system => computer
      )
    end

    def build_physical_server_profiles(physical_server_profile)
      # Builds out collection physical_server_profiles
      # Object types:
      #   - physical_server_profile - ServerProfile, object obtained by intersight client
      # Returns:
      #   ManageIQ's object ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServerProfile
      assigned_server = physical_server_profile.assigned_server.nil? ? nil : persister.physical_servers.lazy_find(physical_server_profile.assigned_server.moid)
      associated_server = physical_server_profile.associated_server.nil? ? nil : persister.physical_servers.lazy_find(physical_server_profile.associated_server.moid)
      persister.physical_server_profiles.build(
        :ems_ref           => physical_server_profile.moid,
        :assigned_server   => assigned_server,
        :associated_server => associated_server,
        :name              => physical_server_profile.name
      )
    end

    # Helper methods to the ones that directly build inventory collections

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
