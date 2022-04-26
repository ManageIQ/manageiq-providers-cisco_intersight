FactoryBot.define do
  factory :ems_cisco_intersight_physical_infra,
          :aliases => ["manageiq/providers/cisco_intersight/physical_infra"],
          :class   => "ManageIQ::Providers::CiscoIntersight::PhysicalInfraManager",
          :parent  => :ems_physical_infra do
    trait :auth do
      after(:create) do |ems|
        ems.authentications << FactoryBot.create(
          :authentication,
          :userid   => "keyid",
          :password => "secretkey"
        )
      end
    end

    trait :vcr do
      after(:create) do |ems|
        secrets = Rails.application.secrets.cisco_intersight
        ems.authentications << FactoryBot.create(
          :authentication,
          :userid   => secrets[:key_id],
          :password => secrets[:secret_key]
        )
      end
    end
  end
end
