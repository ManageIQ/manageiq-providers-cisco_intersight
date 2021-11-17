module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < Inventory::Collector

    def collect
      # TODO(Tjaz Erzen): Collect some data from made-up sdk.
      # For every collected data call function, defined below
    end

    def connection
      @connection ||= manager.connect
    end

    def vms
      connection.vms
    end

    # TODO(Tjaz Erzen): Create helper functions that will collect individual data

  end
end
