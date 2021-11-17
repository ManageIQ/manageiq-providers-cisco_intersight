module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < Inventory::Collector

    def collect

      # <some sample data will be parsed here from mock class MyRubySDK

      # TODO(Tjaz Erzen): Collect some data from made-up sdk.
      # For every collected data call function, defined below
    end

    def connection
      @connection ||= manager.connect
    end

    def vms
      # vms should call the gem we're creating already. Schematically represents the data we're going to get
      connection.vms
    end

    # TODO(Tjaz Erzen): Create helper functions that will collect individual data

  end
end
