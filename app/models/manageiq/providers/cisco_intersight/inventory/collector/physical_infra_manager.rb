module ManageIQ::Providers::CiscoIntersight
  class Inventory::Collector::PhysicalInfraManager < ManageIQ::Providers::Inventory::Collector

    # ManageIQ::Providers::CiscoIntersight::Inventory::Collector::PhysicalInfraManager

    def collect

      # <some sample data will be parsed here from mock class MyRubySDK

      # TODO(Tjaz Erzen): Collect some data from made-up sdk.
      # For every collected data call function, defined below
      # events
      vms
    end

    def connection
      # TODO: When the gem is finished, uncomment the line below and remove the ones below it.
      # @connection ||= manager.connect

      @connection ||= ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::MyRubySDK.new
    end

    def vms
      @vms ||= connection.vms
    end

    def events
      @events ||= connection.events
    end

  end
end
