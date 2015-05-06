require 'active_model'
require 'segment/analytics'
require 'voight_kampff'
require 'browser'

require 'analytics_instrumentation/analytics_attribution'
require 'analytics_instrumentation/analytics_mapping'
require 'analytics_instrumentation/config'

module AnalyticsInstrumentation
  include AnalyticsAttribution

  class << self
    def included(base)
      @@segment = Segment::Analytics.new({
          write_key:  @@config.segment_write_key,
          on_error:   @@config.error_handler
      })

      base.class_eval do
        base.send(:after_filter, :analyticsLogPageView)
        base.send(:after_filter, :analyticsCheckSessionStart)
      end
    end

    def configure(&proc)
      @@config ||= AnalyticsInstrumentation::Config.new
      yield @@config

      # unless @config.valid?
      #   errors = @config.errors.full_messages.join(', ')
      #   raise AnalyticsInstrumentation::Config::Invalid.new(errors)
      # end
    end
  end

  def analyticsCheckSessionStart
    begin
      return if skip_analytics?
      if current_user
        if !session[:last_seen] || session[:last_seen] < 30.minutes.ago
          analyticsTrackEvent("Session Start")
          if @@config.intercom? && Rails.env.production?
            begin
              Intercom.post("https://api.intercom.io/users", {user_id:current_user.id, new_session:true})
            rescue
            end
          end
        end
        session[:last_seen] = Time.now
      else
        if session[:last_seen_logged_out].nil? || session[:last_seen_logged_out] < 30.minutes.ago
          analyticsTrackEvent("Session Start")
        end
        session[:last_seen_logged_out] = Time.now
      end
    rescue => e
      logger.debug "Errpr found in analyticsCheckSessionStart: #{e.inspect}"
      @@config.error_handler.call(e, "Analytics Check Session Crash: #{request.filtered_path}")
    end
  end

  def analyticsLogPageView
    begin
      return if skip_analytics?
      return if self.status >= 400

      page_view_event = AnalyticsMapping.to_event(params, self.view_assigns)

      if page_view_event
        if current_user
          analyticsSetPerson(current_user)
        end
        analyticsTrackEvent page_view_event[:name], page_view_event[:parameters]
        analyticsStoreOriginatingPage page_view_event
      end

      properties = {
        page: request.path
      }

      track_page_view = request.xhr? ? @@config.track_ajax_as_page_view : true

      analyticsTrackEvent("Page View", properties) if track_page_view
    rescue => e
      logger.debug "Errpr found in analyticsLogPageView: #{e.inspect}"
      @@config.error_handler.call(e, "Analytics Crash: #{request.filtered_path}")
    end
  end

  def analyticsStoreOriginatingPage(page_view_event)
    if !request.xhr?
      session["previous-page-type"]       = page_view_event[:name]
      session["previous-page-identifier"] = page_view_event[:page_identifier]
    end
  end

  def analyticsApplyOriginatingPage(properties)
    properties["Originating Page Identifier"] = session["previous-page-identifier"]
    properties["Originating Page Type"]       = session["previous-page-type"]
  end

  def analyticsAliasUser(user_id)
    return if skip_analytics?

    aliasProperties = {
      previous_id: session[:analytics_id],
      user_id: user_id
    }

    logger.debug "Analytics.alias #{aliasProperties}"
    @@segment.alias(aliasProperties)
    @@segment.flush
  end

  def analyticsSetPerson(user)
    return if skip_analytics?

    user_traits = instance_exec(user, &@@config.custom_user_traits)

    properties = {
      user_id: user.id,
      traits: (user_traits||{}),
      integrations: {
        # Don't send leads to C.io if they don't have an email
        "Customer.io" => (!user.email.blank?)
      }
    }

    logger.debug "Analytics.identify #{JSON.pretty_generate(properties)}"
    @@segment.identify(properties)
  end

  def analyticsSuperProperties
    superProperties = {
      "Raw Analytics ID" => raw_analytics_id,
      "Ajax" => !request.xhr?.nil?,
      "Platform" => analyticsPlatform
    }
    if current_user
      user_traits = instance_exec(current_user, &@@config.custom_user_traits)
      superProperties.merge!({user:user_traits}) if user_traits
    end
    superProperties
  end

  def analyticsTrackEvent(name, properties={})
    return if skip_analytics?

    properties ||= {}

    properties["logged_in"] = !!current_user
    properties["source"]    = params[:source] if params[:source]

    properties.merge! analyticsSuperProperties
    add_attribution properties

    # User defined extra props, called in context
    extra_props = instance_exec(&@@config.extra_event_properties)
    properties.merge! (extra_props || {})

    analyticsApplyOriginatingPage properties

    analyticsProperties = {
      user_id: analyticsID,
      event: name,
      properties: properties,
      context: {
        userAgent: request.env['HTTP_USER_AGENT'],
        ip: request.remote_ip,
        'Google Analytics' => {
          clientId: googleAnalyticsID
        }
      },
      integrations: {
        # Don't send leads to C.io if they don't have an email
        "Customer.io" => !!current_user
      }
    }

    logger.debug "Analytics.track #{JSON.pretty_generate(analyticsProperties)}"
    @@segment.track(analyticsProperties)
  end

  def raw_analytics_id
    session[:analytics_id] ||= SecureRandom.uuid
    session[:analytics_id]
  end

  def analyticsID
    if current_user then return current_user.id end
    raw_analytics_id
  end

  private
  def analyticsPlatform
    case
    when browser.mobile?            then "Mobile"
    when browser.platform != :other then "Desktop"
    else
      "Other"
    end
  end

  def googleAnalyticsID
    ck = cookies[:_ga]
    return "1.1" if ck.nil?
    parts = ck.split(".")
    "#{parts[2]}.#{parts[3]}"
  end

  def skip_analytics?
    return true if Rails.env.test? || ENV['RAILS_ENV']=='test' || ENV['RACK_ENV']=='test'
    return true if request.bot?
    return true if request.user_agent.nil?
    bad_strings = ["http:", "https:", "twitterbot", "bingbot", "googlebot", "mediapartners-google", "Webhook"]
    return true if bad_strings.any? { |s| !request.user_agent.downcase.index(s).nil? }
    false
  end
end
