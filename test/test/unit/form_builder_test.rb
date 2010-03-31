require 'test_helper'

class FormBuilderTest < ActiveSupport::TestCase

  test "drop_downs_instance returns correct instance" do
    instance = Vogue::FormBuilder.new(nil, nil, nil, nil, nil)
    assert instance.send(:drop_downs_instance).is_a?(Dropdowns)
  end

  test "drop_downs fetches requested data" do
    instance = Vogue::FormBuilder.new(nil, nil, nil, nil, nil)
    assert_equal instance.send(:drop_down, :priorities, {}), Dropdowns.new(nil).priorities
  end
end
