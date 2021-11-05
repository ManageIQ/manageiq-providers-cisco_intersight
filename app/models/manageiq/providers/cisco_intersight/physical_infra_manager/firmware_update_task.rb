class ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::FirmwareUpdateTask < ManageIQ::Providers::PhysicalInfraManager::FirmwareUpdateTask
  include_concern 'StateMachine'
end
