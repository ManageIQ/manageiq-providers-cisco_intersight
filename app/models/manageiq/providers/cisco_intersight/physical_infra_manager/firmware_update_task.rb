module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::FirmwareUpdateTask \
      < ManageIQ::Providers::PhysicalInfraManager::FirmwareUpdateTask
    include_concern 'StateMachine'
  end
end