require 'test_helper'

class AnalyticsInstrumentationTest < ActiveSupport::TestCase
  test "All analytics routes are valid" do
    mappings = AnalyticsMapping.createMappings
    for method in mappings.keys
      controller, action = method.to_s.split("__")
      begin
        Rails.application.routes.url_helpers.url_for(controller: controller, action: action, id: 1, slug: "a", page: 1, issue_number: 1, user_id: 1, username: 'a', user_collection_id: 1, followable_type: "User", followable_id: 1, host: "canopy.co")
      rescue
        throw "No route for route with analytics instrumentation: #{method}"
      end
    end
  end
end
