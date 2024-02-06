module ManageIQ::Providers::CiscoIntersight
  module PhysicalInfraManager::Operations
    extend ActiveSupport::Concern
    include Power
    include Led
    include Firmware
    include Lifecycle
    include ServerProfileAssignment
  end
end
