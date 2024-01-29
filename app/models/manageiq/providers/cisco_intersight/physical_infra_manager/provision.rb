module ManageIQ::Providers::CiscoIntersight
  class PhysicalInfraManager::Provision \
      < ::PhysicalServerProvisionTask
    include StateMachine
  end
end
