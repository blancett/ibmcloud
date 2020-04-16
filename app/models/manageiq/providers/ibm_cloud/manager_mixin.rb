module ManageIQ::Providers::IbmCloud::ManagerMixin
  extend ActiveSupport::Concern

  def connect(options = {})
    raise MiqException::MiqHostError, _("No credentials defined") if missing_credentials?(options[:auth_type])

    client_id  = options[:user] || authentication_userid(options[:auth_type])
    client_key = options[:pass] || authentication_password(options[:auth_type])

    self.class.raw_connect(client_id, client_key, azure_tenant_id, subscription, options[:proxy_uri] || http_proxy_uri, provider_region, default_endpoint)
  end

  def verify_credentials(_auth_type = nil, options = {})
    connect(options)
  end

  def edit_with_params(params)
    default_endpoint = params.delete("endpoints").dig("default")
    default_authentication = params.delete("authentications").dig("default")

    tap do |ems|
      ems.default_authentication.assign_attributes(default_authentication)
      ems.default_endpoint.assign_attributes(default_endpoint)

      ems.assign_attributes(params)

      ems.save!
    end
  end

  module ClassMethods
    def params_for_create
      @params_for_create ||= {
        :fields => [
          {
            :component  => "select-field",
            :name       => "provider_region",
            :label      => _("Region"),
            :isRequired => true,
            :validate   => [{:type => "required-validator"}],
            :options    => ManageIQ::Providers::Azure::Regions.all.sort_by { |r| r[:description] }.map do |region|
              {
                :label => region[:description],
                :value => region[:name]
              }
            end
          },
          {
            :component  => "text-field",
            :name       => "uid_ems",
            :label      => _("Tenant ID"),
            :isRequired => true,
            :validate   => [{:type => "required-validator"}],
          },
          {
            :component  => "text-field",
            :name       => "subscription",
            :label      => _("Subscription ID"),
            :isRequired => true,
            :validate   => [{:type => "required-validator"}],
          },
          {
            :component => 'sub-form',
            :name      => 'endpoints',
            :title     => _("Endpoint"),
            :fields    => [
              {
                :component              => 'validate-provider-credentials',
                :name                   => 'authentications.default.valid',
                :validationDependencies => %w[type zone_id provider_region subscription uid_ems],
                :fields                 => [
                  {
                    :component => "text-field",
                    :name      => "endpoints.default.url",
                    :label     => _("Endpoint URL"),
                  },
                  {
                    :component  => "text-field",
                    :name       => "authentications.default.userid",
                    :label      => _("Client ID"),
                    :helperText => _("Should have privileged access, such as root or administrator."),
                    :isRequired => true,
                    :validate   => [{:type => "required-validator"}]
                  },
                  {
                    :component  => "password-field",
                    :name       => "authentications.default.password",
                    :label      => _("Client Key"),
                    :type       => "password",
                    :isRequired => true,
                    :validate   => [{:type => "required-validator"}]
                  },
                ],
              },
            ],
          },
        ],
      }.freeze
    end

    def create_from_params(params)
      endpoints = params.delete("endpoints") || {'default' => {}} # Fall back to an empty default endpoint
      authentications = params.delete("authentications")

      new(params).tap do |ems|
        endpoints.each do |authtype, endpoint|
          ems.endpoints.new(endpoint.merge(:role => authtype))
        end

        authentications.each do |authtype, authentication|
          ems.authentications.new(authentication.merge(:authtype => authtype))
        end

        ems.save!
      end
    end

    def verify_credentials(args)
      region           = args["region"]
      subscription     = args["subscription"]
      azure_tenant_id  = args["uid_ems"]
      default_endpoint = args.dig("authentications", "default")
      endpoint_url = args.dig("endpoints", "default", "url")

      client_id, client_key = default_endpoint&.values_at("userid", "password")

      client_key = MiqPassword.try_decrypt(client_key)
      # Pull out the password from the database if a provider ID is available
      client_key ||= find(args["id"]).authentication_password('default')

      !!raw_connect(client_id, client_key, azure_tenant_id, subscription, http_proxy_uri, region, endpoint_url)
    end

    def raw_connect(client_id, client_key, azure_tenant_id, subscription, proxy_uri = nil, provider_region = nil, endpoint = nil)
      if subscription.blank?
        raise MiqException::MiqInvalidCredentialsError, _("Incorrect credentials - check your Azure Subscription ID")
      end
    end

    def connection_rescue_block
      print "rescue"
    end

    def environment_for(region)
      case region
      when /germany/i
        print "germ"
      when /usgov/i
        print "usa"
      else
        print "else country"
      end
    end
  end
end