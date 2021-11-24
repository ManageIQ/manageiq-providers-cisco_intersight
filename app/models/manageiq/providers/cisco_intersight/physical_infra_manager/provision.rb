module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::Provision \
      < ::PhysicalServerProvisionTask
    include_concern 'StateMachine'
  end
end
