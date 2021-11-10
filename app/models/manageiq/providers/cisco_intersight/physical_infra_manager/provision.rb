class ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::Provision \
    < ::PhysicalServerProvisionTask
  include_concern 'StateMachine'
end
