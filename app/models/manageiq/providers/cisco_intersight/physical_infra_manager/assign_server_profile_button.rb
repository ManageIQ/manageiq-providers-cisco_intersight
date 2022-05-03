class ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::AssignServerProfileButton < ApplicationHelper::Button::Basic
  needs :@record

  def disabled?
    !@record.assigned_server_profile.nil?
  end
end
