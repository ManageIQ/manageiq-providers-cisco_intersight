module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::FirmwareUpdateTask \
      < ManageIQ::Providers::PhysicalInfraManager::FirmwareUpdateTask
    include StateMachine
  end
end
