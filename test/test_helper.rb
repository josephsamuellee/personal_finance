ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Rails 7.2 filters lines by overriding the Minitest 5 class-method signature.
# Minitest 6, required by Ruby 4, calls run(klass, method_name, reporter).
module Rails
  module LineFiltering
    def run(klass, method_name, reporter)
      super
    end
  end
end

module ActiveSupport
  class TestCase
    parallelize(workers: 1)

    setup do
      Rack::Attack.cache.store.clear
    end

    def create_user(email: "ada@example.com", password: "password-password")
      User.create!(email_address: email, password:, password_confirmation: password)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    def sign_in_as(user, password: "password-password")
      post session_path, params: { email_address: user.email_address, password: }
    end
  end
end
