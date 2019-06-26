module ChefDK
  class Dist
    # This class is not fully implemented, depending on it is not recommended!

    # The full marketing name of the product
    PRODUCT = "ChefDK".freeze

    # The chef executable, as in `chef gem install` or `chef generate cookbook`
    EXEC = "chef".freeze

    # the name of the overall infra product
    INFRA_PRODUCT = "Chef Infra".freeze

    INFRA_CLIENT_PRODUCT = "Chef Infra Client".freeze
    INFRA_CLIENT_CLI = "chef-client".freeze

    SERVER_PRODUCT = "Chef Infra Server".freeze

    INSPEC_PRODUCT = "Chef InSpec".freeze
    INSPEC_CLI = "inspec".freeze

    WORKFLOW = "Chef Workflow (Delivery)".freeze

    # Chef-Zero's product name
    ZERO_PRODUCT = "Chef Infra Zero".freeze
  end
end
