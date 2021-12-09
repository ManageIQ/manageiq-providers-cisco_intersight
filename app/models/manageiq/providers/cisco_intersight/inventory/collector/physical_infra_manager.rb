module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    def collect
      vms
    end

    def connection
      @connection ||= manager.connect
    end

    # def vms
    #   @vms ||= connection.vms
    # end

    def vms
      @vms ||= connection.get_physical_summaries_temporary.Results
    end

  end
end
