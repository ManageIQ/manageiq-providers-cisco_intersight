module ManageIQ::Providers::CiscoIntersight
  class Inventory::Parser::PhysicalInfraManager < Inventory::Parser

    def parse
      physical_servers
    end 

    def physical_servers
      collector.physical_servers.each do |s|

        persister.physical_servers.build(
          :ems_ref                => s.Moid,
       	  :health_state           => "dummy",  
       	  :hostname               => "dummy",  
       	  :name                   => s.Name,
       	  :physical_chassis       => "dummy",
          :physical_rack          => "dummy",  
       	  :power_state            => "dummy",
          :raw_power_state        => "dummy",
          :type                   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::PhysicalServer",
        )
      end
    end


  end
end
