module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector < ManageIQ::Providers::Inventory::Collector
    require_nested :PhysicalInfraManager

    def connection
      @connection ||= manager.connect
    end
  
    def vms
      connection.vms
    end
  end
end
