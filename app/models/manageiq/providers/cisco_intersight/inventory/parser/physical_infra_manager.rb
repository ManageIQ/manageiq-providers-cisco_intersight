module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      vms
    end

    # def vms
    #   collector.vms.each do |inventory|
    #
    #     persister.vms.build(
    #       :ems_ref         => inventory.id,
    #       :uid_ems         => inventory.id,
    #       :name            => inventory.name,
    #       :location        => inventory.location,
    #       :vendor          => inventory.vendor
    #     )
    #   end
    # end

    def vms
      collector.vms.each do |inventory|

        persister.vms.build(
          :ems_ref         => inventory.Moid,
	  :uid_ems 	   => inventory.Moid,
	  :name 	   => inventory.Name,
          :location	   => "dc-1",
          :vendor	   => "unknown"  # inventory.Vendor
        )
      end
    end

  end
end
