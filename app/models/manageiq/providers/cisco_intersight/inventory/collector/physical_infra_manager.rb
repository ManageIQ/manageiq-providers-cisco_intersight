module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    def collect

      # Establish connection. Connection is inside ManagerMixin which sets API key and keyid-d
      connection

      # Initialize API endpoints
      firmware_api
      compute_api
      equipment_api
      asset_api
      adapter_api
      management_api
      storage_api
      network_api
      port_api
      ether_api

      # Initialize the variables that may be memoized for the duration of the refresh run
      physical_servers
      physical_racks
      firmware_firmware_summaries
      network_elements
      physical_chassis
    end

    # Methods that are directly used by parser

    def device_contract_informations
      # Returns an array with objects of type DeviceContractInformation
      @device_contract_informations ||= asset_api.get_asset_device_contract_information_list.results
    end

    def physical_racks
      @physical_racks ||= compute_api.get_compute_rack_unit_list.results
    end

    def firmware_firmware_summaries
      @firmware_firmware_summaries ||= firmware_api.get_firmware_firmware_summary_list.results
    end

    def physical_servers
      @physical_servers ||= compute_api.get_compute_physical_summary_list.results
    end

    def physical_chassis
      @physical_chassis ||= equipment_api.get_equipment_chassis_list.results
    end

    def network_elements
      @network_elements ||= network_api.get_network_element_list.results
    end

    def get_device_contract_information_from_device_moid(registered_device_moid)
      device_contract_informations.find { |c| c.registered_device.moid == registered_device_moid }
    end

    def get_firmware_firmware_summary_from_server_moid(server_moid)
      firmware_firmware_summaries.find { |c| c.server.moid == server_moid}
    end

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

    delegate :get_ether_physical_port_by_moid, :to => :ether_api

    delegate :get_port_group_by_moid, :to => :port_api

    delegate :get_equipment_switch_card_by_moid, :to => :equipment_api

    delegate :get_equipment_locator_led_by_moid, :to => :equipment_api

    delegate :get_storage_controller_by_moid, :to => :storage_api

    delegate :get_compute_board_by_moid, :to => :compute_api

    delegate :get_adapter_unit_by_moid, :to => :adapter_api

    delegate :get_asset_device_registration_by_moid, :to => :asset_api

    delegate :get_firmware_running_firmware_by_moid, :to => :firmware_api

    delegate :get_compute_blade_by_moid, :to => :compute_api

    delegate :get_compute_rack_unit_by_moid, :to => :compute_api

    private

    # API endpoint declaration
    def firmware_api
      @firmware_api ||= IntersightClient::FirmwareApi.new
    end

    def compute_api
      @compute_api ||= IntersightClient::ComputeApi.new
    end

    def equipment_api
      @equipment_api ||= IntersightClient::EquipmentApi.new
    end

    def asset_api
      @asset_api ||= IntersightClient::AssetApi.new
    end

    def adapter_api
      @adapter_api ||= IntersightClient::AdapterApi.new
    end

    def management_api
      @management_api ||= IntersightClient::ManagementApi.new
    end

    def storage_api
      @storage_api ||= IntersightClient::StorageApi.new
    end

    def network_api
      @network_api ||= IntersightClient::NetworkApi.new
    end

    def port_api
      @port_api ||= IntersightClient::PortApi.new
    end

    def ether_api
      @ether_api ||= IntersightClient::EtherApi.new
    end

    # API key and keyid configuration

    def connection
      # Sets API key and keyid for the manager
      @connection ||= manager.connect
    end
  end
end
