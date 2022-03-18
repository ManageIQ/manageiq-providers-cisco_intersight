module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    def collect

      set_configuration

      physical_servers
      physical_racks
      physical_server_network_devices
      firmware_inventory
      network_elements
    end

    def set_configuration
      @connection ||= manager.connect
    end

    def get_firmware_api
      IntersightClient::FirmwareApi.new
    end

    def get_compute_api
      IntersightClient::ComputeApi.new
    end

    def get_equipment_api
      IntersightClient::EquipmentApi.new
    end

    def get_asset_api
      IntersightClient::AssetApi.new
    end

    def get_memory_api
      IntersightClient::MemoryApi.new
    end

    def get_adapter_api
      IntersightClient::AdapterApi.new
    end

    def get_management_api
      IntersightClient::ManagementApi.new
    end

    def get_storage_api
      IntersightClient::StorageApi.new
    end

    def network_api
      @network_api ||= IntersightClient::NetworkApi.new
    end

    def get_port_api
      IntersightClient::PortApi.new
    end

    def get_ether_api
      IntersightClient::EtherApi.new
    end

    def get_device_contract_informations
      # Returns an array with objects of type DeviceContractInformation
      get_asset_api.get_asset_device_contract_information_list.results
    end

    def get_device_contract_information_from_device_moid(registered_device_moid)
      get_device_contract_informations.select { |c| c.registered_device.moid == registered_device_moid }[0]
    end

    delegate :get_adapter_ext_eth_interface_by_moid, :to => :get_adapter_api

    delegate :get_ether_physical_port_by_moid, :to => :get_ether_api

    delegate :get_port_group_by_moid, :to => :get_port_api

    delegate :get_equipment_switch_card_by_moid, :to => :get_equipment_api

    delegate :get_equipment_locator_led_by_moid, :to => :get_equipment_api

    delegate :get_storage_controller_by_moid, :to => :get_storage_api

    delegate :get_compute_board_by_moid, :to => :get_compute_api

    delegate :get_adapter_unit_by_moid, :to => :get_adapter_api

    delegate :get_asset_device_registration_by_moid, :to => :get_asset_api

    delegate :get_firmware_running_firmware_by_moid, :to => :get_firmware_api

    def get_rack_unit_from_physical_summary_moid(moid)
      physical_racks.select { |c| c.registered_device.moid == moid }[0]
    end

    delegate :get_management_controller_by_moid, :to => :get_management_api

    delegate :get_compute_blade_by_moid, :to => :get_compute_api

    delegate :get_compute_rack_unit_by_moid, :to => :get_compute_api

    def get_source_object_from_physical_server(physical_summary)
      # physical_summary represents API object, class IntersightClient::ComputePhysicalSummary
      # Returns API object of either class IntersightClient::ComputeBlade or IntersightClient::ComputeRackUnit,
      # depending on attribute source_object_type
      source_object_type = physical_summary.source_object_type
      source_object_moid = physical_summary.moid
      if source_object_type == "compute.Blade"
        get_compute_blade_by_moid(source_object_moid)
      else
        get_compute_rack_unit_by_moid(source_object_moid)
      end
    end

    def physical_racks
      get_compute_api.get_compute_rack_unit_list.results
    end

    def physical_server_network_devices
      get_equipment_api.get_equipment_device_summary_list.results.reject { |c| c.source_object_type == "compute.RackUnit" }
    end

    def firmware_inventory
      get_firmware_api.get_firmware_firmware_summary_list.results
    end

    def physical_servers
      get_compute_api.get_compute_physical_summary_list.results
    end

    def compute_blades
      get_compute_api.get_compute_blade_list.results
    end

    def physical_chassis
      get_equipment_api.get_equipment_chassis_list.results
    end

    def network_elements
      network_api.get_network_element_list.results
    end



  end
end
