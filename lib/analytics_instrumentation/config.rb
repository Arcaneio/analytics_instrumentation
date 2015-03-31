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
      @@REQUIRED_CALLABLES.each do |callable|
        unless self.send(callable).is_a?(Proc)
          errors.add(callable, "must be a Proc")
        end
      end
    end

    def initialize
      self.extra_event_properties = Proc.new {}
      self.custom_user_traits     = Proc.new {}
      self.error_handler          = Proc.new { |e, msg=""| raise }
    end

    def intercom?
      Intercom rescue false
    end

    private
  end
end
