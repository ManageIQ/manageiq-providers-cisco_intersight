module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    def collect
      
      set_configuration

      physical_servers
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

    def firmware_inventory
      @firmware_inventory ||= get_firmware_inventory_api.get_firmware_running_firmware_list().results
    end

    def physical_servers
      @physical_servers ||= get_compute_api.get_compute_physical_summary_list.results
    end

  end
end
