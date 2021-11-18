module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    # ManageIQ::Providers::CiscoIntersight::Inventory::Parser::PhysicalInfraManager

    def parse

      # <some sample data will be parsed here from collector, which gathers info from MyRubySDK>

      # TODO: After fully built out collector.rb, parse the gathered data.
      # Each function will parse a part of gathered data
      <<-DOC
      physical_servers
      physical_server_details
      hardwares
      physical_racks
      physical_chassis
      physical_chassis_details
      firmwares
      DOC

      vms
    end

    def vms
      collector.vms.each do |inventory|
        inventory_object = persister.vms.find_or_build(inventory.id.to_s)
        inventory_object.name = inventory.name
        inventory_object.location = inventory.location
        inventory_object.vendor = inventory.vendor
      end
    end

    # With connection not set up yet, I parse data from mock class MyRubySDK.
  end
end
