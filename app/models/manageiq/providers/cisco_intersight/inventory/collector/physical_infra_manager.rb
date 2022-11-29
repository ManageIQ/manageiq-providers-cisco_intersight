module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector
    require 'intersight_client'
    def collect
      # Initialize the variables that may be memoized for the duration of the refresh run
      physical_servers
      decomissioned_servers
      physical_racks
      physical_server_profiles
      physical_server_profile_templates
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

    def decomissioned_servers
      opts = {:filter => "(Lifecycle eq 'Decommissioned') and (IndexMotypes eq  'equipment.Identity')"}
      @decomissioned_servers ||= search_api.get_search_search_item_list(opts).results
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

    def physical_server_profiles
      @physical_server_profiles ||= server_api.get_server_profile_list.results
    rescue IntersightClient::ApiError => e
      @physical_server_profiles = {}
      _log.error("Collecting process of Server Profiles has failed: #{e.response_body}. There might be a potential license issue.")
    end

    def physical_server_profile_templates
      @physical_server_profile_templates ||= server_api.get_server_profile_template_list.results
    rescue IntersightClient::ApiError => e
      @physical_server_profile_templates = {}
      _log.error("Collecting process of Server Profiles Templates has failed: #{e.response_body}. There might be a potential license issue.")
    end

    def device_contract_informations_by_moid
      @device_contract_informations_by_moid ||= device_contract_informations.index_by do |dev_contract_info|
        dev_contract_info.registered_device.moid
      end
    end

    def firmware_firmware_summary_by_moid
      @firmware_firmware_summary_by_moid ||= firmware_firmware_summaries.index_by do |firmware_firmware_summary|
        firmware_firmware_summary.server.moid
      end
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

    def compute_blades
      compute_api.get_compute_blade_list.results
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

    delegate :get_network_element_summary_by_moid, :to => :network_api

    delegate :get_adapter_host_eth_interface_by_moid, :to => :adapter_api

    private

    # API endpoint declaration
    def firmware_api
      @firmware_api ||= IntersightClient::FirmwareApi.new(api_client)
    end

    def compute_api
      @compute_api ||= IntersightClient::ComputeApi.new(api_client)
    end

    def equipment_api
      @equipment_api ||= IntersightClient::EquipmentApi.new(api_client)
    end

    def asset_api
      @asset_api ||= IntersightClient::AssetApi.new(api_client)
    end

    def adapter_api
      @adapter_api ||= IntersightClient::AdapterApi.new(api_client)
    end

    def management_api
      @management_api ||= IntersightClient::ManagementApi.new(api_client)
    end

    def storage_api
      @storage_api ||= IntersightClient::StorageApi.new(api_client)
    end

    def network_api
      @network_api ||= IntersightClient::NetworkApi.new(api_client)
    end

    def port_api
      @port_api ||= IntersightClient::PortApi.new(api_client)
    end

    def ether_api
      @ether_api ||= IntersightClient::EtherApi.new(api_client)
    end

    def search_api
      @search_api ||= IntersightClient::SearchApi.new(api_client)
    end

    def server_api
      @server_api ||= IntersightClient::ServerApi.new(api_client)
    end

    def bulk_api
      @bulk_api ||= IntersightClient::BulkApi.new(api_client)
    end

    # API key and keyid configuration
    def api_client
      # Sets API key and keyid for the manager
      @api_client ||= manager.connect
    end
  end
end
