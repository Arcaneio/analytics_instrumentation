module AnalyticsInstrumentation
  class Config
    include ActiveModel::Validations

    class Invalid < StandardError; end

    attr_accessor :extra_event_properties
    attr_accessor :custom_user_traits
    attr_accessor :error_handler
    attr_accessor :segment_write_key

    validates_presence_of :segment_write_key

    @@REQUIRED_CALLABLES = [
      :extra_event_properties,
      :custom_user_traits,
      :error_handler
    ]
    validate do
      @@REQUIRED_CALLABLES.each |callable| do
        unless self.send(callable).respond_to?(:call)
          errors.add(callable, "must be a callable object (eg. Proc)")
        end
      end
    end

    def initialize
      self.extra_event_properties = -> {}
      self.custom_user_traits     = -> {}
      self.error_handler          = (msg) -> { raise }
    end

    def custom_user_traits(user)
      self.custom_user_traits(user) || {}
    end

    def extra_event_properties
      self.extra_event_properties() || {}
    end

    def intercom?
      Intercom rescue false
    end

    private
  end
end
