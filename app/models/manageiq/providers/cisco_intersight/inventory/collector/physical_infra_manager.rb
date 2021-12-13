module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    def collect
      physical_servers
    end

    def connection
      @connection ||= manager.connect
    end

    def physical_servers
      @physical_servers ||= connection.get_physical_summaries_temporary.Results
    end

  end
end
