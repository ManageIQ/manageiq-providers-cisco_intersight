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

    def physical_racks
      get_equipment_api.get_equipment_device_summary_list.results.select { |c| c.source_object_type == "compute.RackUnit" }
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
