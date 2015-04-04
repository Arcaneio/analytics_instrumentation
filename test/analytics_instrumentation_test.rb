require 'test_helper'

class AnalyticsInstrumentationTest < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, AnalyticsInstrumentation
  end

  test "C.io wont see users without emails" do
    assert false, "TODO"
  end


end
