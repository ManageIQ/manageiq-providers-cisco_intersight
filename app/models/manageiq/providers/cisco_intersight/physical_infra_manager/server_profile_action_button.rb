class ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::ServerProfileActionButton < ApplicationHelper::Button::Basic
  needs :@record

  def disabled?
    @record.assigned_server_profile.blank?
  end
end
