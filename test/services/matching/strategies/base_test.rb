require "test_helper"

class Matching::Strategies::BaseTest < ActiveSupport::TestCase
  test "subclases deben implementar #call" do
    strategy = Matching::Strategies::Base.new(raw_name: "x", normalized_name: "x")
    assert_raises(NotImplementedError) { strategy.call }
  end
end
