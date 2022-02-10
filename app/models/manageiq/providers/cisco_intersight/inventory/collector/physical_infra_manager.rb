module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    def collect

      set_configuration

      physical_servers
      physical_racks
      physical_server_network_devices
      firmware_inventory

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

    def get_device_contract_informations
      # Returns an array with objects of type DeviceContractInformation
      get_asset_api.get_asset_device_contract_information_list.results
    end

    def get_device_contract_information_from_device_moid(registered_device_moid)
      get_device_contract_informations.select{|c| c.registered_device.moid == registered_device_moid}[0]
    end

    def get_equipment_locator_led_by_moid(moid)
      get_equipment_api.get_equipment_locator_led_by_moid(moid)
    end

    def get_storage_controller_by_moid(moid)
      get_storage_api.get_storage_controller_by_moid(moid)
    end

    def get_compute_board_by_moid(moid)
      get_compute_api.get_compute_board_by_moid(moid)
    end

    def get_adapter_unit_by_moid(moid)
      get_adapter_api.get_adapter_unit_by_moid(moid)
    end

    def get_asset_device_registration_by_moid(moid)
      get_asset_api.get_asset_device_registration_by_moid(moid)
    end

    def get_rack_unit_from_physical_summary_moid(moid)
      physical_racks.select { |c| c.registered_device.moid == moid }[0]
    end

    def get_management_controller_by_moid(moid)
      get_management_api.get_management_controller_by_moid(moid)
    end

    def get_compute_blade_by_moid(moid)
      get_compute_api.get_compute_blade_by_moid(moid)
    end

    def get_compute_rack_unit_by_moid(moid)
      get_compute_api.get_compute_rack_unit_by_moid(moid)
    end

    def get_source_object_from_physical_server(physical_summary)
      # physical_summary represents API object, class IntersightClient::ComputePhysicalSummary
      # Returns API object of either class IntersightClient::ComputeBlade or IntersightClient::ComputeRackUnit,
      # depending on attribute source_object_type
      source_object_type = physical_summary.source_object_type
      source_object_moid = physical_summary.moid
      if source_object_type == "compute.Blade"
        source_object = get_compute_blade_by_moid(source_object_moid)
      else
        source_object = get_compute_rack_unit_by_moid(source_object_moid)
      end
      source_object
    end

    def physical_racks
      get_compute_api.get_compute_rack_unit_list.results
    end

    def physical_server_network_devices
      get_equipment_api.get_equipment_device_summary_list.results.reject { |c| c.source_object_type == "compute.RackUnit" } # source_object_type == "adapter.Unit"
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

  end
end
