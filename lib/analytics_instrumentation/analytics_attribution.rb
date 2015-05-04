module AnalyticsAttribution
  def add_attribution(props={})
    # Gather
    attribution_data = {
      first_external_referrer:  get_first_referrer,
      latest_external_referrer: get_latest_referrer,
    }

    attribution_data.merge! get_utm(:first)
    attribution_data.merge! get_utm(:latest)

    # Persist
    attribution_data.each do |k,v|
      set_cookie k, v
    end

    # Merge
    props.merge! attribution_data
  end

  private
  def get_first_referrer
    get_cookie("first_external_referrer") || get_latest_referrer
  end

  def get_latest_referrer
    ref = request.referrer
    bad_host = attribution_host(ref).nil?
    our_host = attribution_host(ref) == attribution_host(request.original_url)
    if ref.blank? || our_host || bad_host
      get_cookie "latest_external_referrer"
    else
      attribution_host(ref)
    end
  end

  def get_utm(which=:latest)
    if which == :first
      first = {
        first_utm_name:     get_cookie('first_utm_name'),
        first_utm_source:   get_cookie('first_utm_source'),
        first_utm_medium:   get_cookie('first_utm_medium'),
        first_utm_term:     get_cookie('first_utm_term'),
        first_utm_content:  get_cookie('first_utm_content')
      }

      return first if first.reject{|k,v| v.nil? }.any?
    end

    name    = params[:utm_campaign]
    source  = params[:utm_source]
    medium  = params[:utm_medium]
    term    = params[:utm_term]
    content = params[:utm_content]

    if name.blank?
      {
        latest_utm_name:     get_cookie('latest_utm_name'),
        latest_utm_source:   get_cookie('latest_utm_source'),
        latest_utm_medium:   get_cookie('latest_utm_medium'),
        latest_utm_term:     get_cookie('latest_utm_term'),
        latest_utm_content:  get_cookie('latest_utm_content')
      }
    else
      {
        latest_utm_name:     name,
        latest_utm_source:   source,
        latest_utm_medium:   medium,
        latest_utm_term:     term,
        latest_utm_content:  content
      }
    end
  end

  def attribution_host(url)
    return nil if url.nil?
    uri = Addressable::URI.parse(url)
    uri.host && uri.host.sub(/\Awww\./,'').downcase
  end

  def set_cookie(key, value)
    stored_value = value.is_a?(Hash) ? value.to_json : value
    cookies[key] = stored_value
  end

  def get_cookie(key)
    output = cookies[key]
    if output && output[0] == "{"
      JSON.parse(output) rescue nil
    else
      output
    end
  end
end
