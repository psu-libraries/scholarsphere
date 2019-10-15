# frozen_string_literal: true

RSpec::Matchers.define :have_jsonb_accessor do |attribute_name|
  match do |model|
    model.respond_to?(attribute_name) &&
      model.respond_to?("#{attribute_name}=") &&
      test_default_value(model, attribute_name) &&
      test_accessor_value(model, attribute_name)
  end

  chain :of_type do |expected_type|
    @expected_type = expected_type
  end

  chain :is_array do
    @is_array = true
  end

  chain :with_default do |default_value|
    @default_value = default_value
  end

  failure_message do |model|
    "expected jsonb_accessor for #{attribute_name} on #{model}"
  end

  failure_message_when_negated do |model|
    "expected jsonb_accessor for #{attribute_name} not to be defined on #{model}"
  end

  description do
    'assert there is an jsonb_accessor of the given name on the supplied object'
  end

  def test_default_value(model, attribute_name)
    return true unless defined?(@default_value)

    model.send(attribute_name) == @default_value
  end

  def test_accessor_value(model, attribute_name)
    value = case @expected_type
            when :string then 'string'
            when :integer then 123
            else 'string'
            end
    value = [value] if @is_array
    model.send("#{attribute_name}=", value)
    model.send(attribute_name) == value
  end
end
