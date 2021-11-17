module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser
    def parse
      # TODO(Tjaz Erzen): Parse made-up sdk
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
  end
end
