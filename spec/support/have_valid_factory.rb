# frozen_string_literal: true

RSpec::Matchers.define :have_valid_factory do |*factory_args|
  match do |_model|
    @factory = FactoryBot.build(*factory_args)
    @factory.save
  end

  description do
    "have a valid factory #{pretty_print(factory_args)}"
  end

  failure_message do |_model|
    "expected factory #{pretty_print(factory_args)} to be valid, but it wasn't:\n" +
      @factory.errors.full_messages.map { |str| "  #{str}" }.join("\n")
  end

  def pretty_print(factory_args)
    factory_args.map(&:inspect).join(', ')
  end
end
