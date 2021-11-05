module ManageIQ::Providers::CiscoIntersight
  module PhysicalInfraManager::Operations
    extend ActiveSupport::Concern

    include_concern "Power"
    include_concern "Led"
    include_concern "Firmware"
  end
end
