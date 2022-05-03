module ManageIQ
  module Providers
    module CiscoIntersight
      module ToolbarOverrides
        class PhysicalServerCenter < ::ApplicationHelper::Toolbar::Override
          button_group(
            'physical_server_policy_choice',
            [
              select(
                :physical_server_lifecycle_choice,
                nil,
                t = N_('Intersight'),
                t,
                :enabled => true,
                :items   => [
                  api_button(
                    :physical_server_decommission,
                    nil,
                    N_('Decommission server'),
                    N_('Decommission'),
                    :icon    => "pficon pficon-off fa-lg",
                    :api     => {
                      :action => 'decommission_server',
                      :entity => 'physical_server'
                    },
                    :confirm => N_("Decommission this server?"),
                    :enabled => true,
                    :options => {:feature => :decommission}
                  ),
                  api_button(
                    :physical_server_recommission,
                    nil,
                    N_('Recommission server'),
                    N_('Recommission'),
                    :icon    => "pficon pficon-off fa-lg",
                    :api     => {
                      :action => 'recommission_server',
                      :entity => 'physical_server'
                    },
                    :confirm => N_("Recommission this server?"),
                    :enabled => true,
                    :options => {:feature => :recommission}
                  ),
                  separator(),
                  button(
                    :physical_server_assign_server_profile,
                    'pficon pficon-add-circle-o fa-lg',
                    t = N_('Assign Server Profile'),
                    t,
                    :data  => {'function'      => 'sendDataWithRx',
                               'function-data' => {:controller     => 'provider_dialogs',
                                                   :button         => :physical_server_assign_server_profile,
                                                   :modal_title    => N_('Assign Server Profile'),
                                                   :component_name => 'ServerProfileForm',
                                                   :action         => 'assign_server'}},
                                                   :klass          => ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager::AssignServerProfileButton
                  ),
                  button(
                    :physical_server_deploy_server_profile,
                    'pficon fa-lg',
                    t = N_('Deploy Server Profile'),
                    t,
                    :data  => {'function'      => 'sendDataWithRx',
                               'function-data' => {:controller     => 'provider_dialogs',
                                                   :button         => :physical_server_deploy_server_profile,
                                                   :modal_title    => N_('Deploy Server Profile'),
                                                   :component_name => 'ServerProfileForm',
                                                   :action         => 'deploy_server'}},
                                                   :klass          => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  ),
                  button(
                    :physical_server_unassign_server_profile,
                    'pficon fa-lg',
                    t = N_('Unassign Server Profile'),
                    t,
                    :data  => {'function'      => 'sendDataWithRx',
                               'function-data' => {:controller     => 'provider_dialogs',
                                                   :button         => :physical_server_unassign_server_profile,
                                                   :modal_title    => N_('Unassign Server Profile'),
                                                   :component_name => 'ServerProfileForm',
                                                   :action         => 'unassign_server'}},
                                                   :klass          => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  ),
                ]
              )
            ]
          )
        end
      end
    end
  end
end
