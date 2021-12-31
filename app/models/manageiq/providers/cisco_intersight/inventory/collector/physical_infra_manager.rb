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

    def get_firmware_inventory_api
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
      physical_racks.select { |c| c.registered_device.moid == moid } [0]
    end

    def get_management_controller_by_moid(moid)
      get_management_api.get_management_controller_by_moid(moid)
    end

    def physical_racks
      get_compute_api.get_compute_rack_unit_list.results
    end

    def physical_server_network_devices
      get_equipment_api.get_equipment_device_summary_list.results.reject { |c| c.source_object_type == "compute.RackUnit" } # source_object_type == "adapter.Unit"
    end
    
    # not sure if this is the right API call. get_firmware_inventory_api.get_firmware_firmware_summary_list gives me empty results,
    # despite being the summary
    # TODO: Find out, if this is the right api call; if it isn't, find the one that is
    def firmware_inventory
      @firmware_inventory ||= get_firmware_inventory_api.get_firmware_running_firmware_list.results
    end

    def physical_servers
      @physical_servers ||= get_compute_api.get_compute_physical_summary_list.results
    end

  end
end
