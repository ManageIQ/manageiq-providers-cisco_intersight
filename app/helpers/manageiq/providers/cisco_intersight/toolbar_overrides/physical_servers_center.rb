module ManageIQ
  module Providers
    module CiscoIntersight
      module ToolbarOverrides
        class PhysicalServersCenter < ::ApplicationHelper::Toolbar::Override
          button_group(
            'physical_server_policy_choice',
            [
              select(
                :physical_server_lifecycle_choice,
                nil,
                t = N_('Cisco Intersight'),
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
                    :confirm => N_("Decommission selected servers?"),
                    :enabled => true,
                    :onwhen  => "1+",
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
                    :confirm => N_("Recommission selected servers?"),
                    :enabled => true,
                    :onwhen  => "1+",
                    :options => {:feature => :recommission}
                  ),
                  separator,
                  button(
                    :physical_server_profile_deploy_server,
                    'pficon fa-lg',
                    t = N_('Deploy Server Profile'),
                    t,
                    :data  => {'function'      => 'sendDataWithRx',
                               'function-data' => {:controller     => 'provider_dialogs',
                                                   :button         => :physical_server_profile_deploy_server,
                                                   :modal_title    => N_('Deploy Server Profile'),
                                                   :component_name => 'ServerProfileForm',
                                                   :action         => 'deploy_server'}},
                    :klass => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  ),
                  button(
                    :physical_server_profile_unassign_server,
                    'pficon fa-lg',
                    t = N_('Unassign Server Profile'),
                    t,
                    :data  => {'function'      => 'sendDataWithRx',
                               'function-data' => {:controller     => 'provider_dialogs',
                                                   :button         => :physical_server_profile_unassign_server,
                                                   :modal_title    => N_('Unassign Server Profile'),
                                                   :component_name => 'ServerProfileForm',
                                                   :action         => 'unassign_server'}},
                    :klass => ApplicationHelper::Button::ButtonWithoutRbacCheck
                  )
                ]
              )
            ]
          )
        end
      end
    end
  end
end
