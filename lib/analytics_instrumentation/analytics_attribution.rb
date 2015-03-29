module AnalyticsAttribution
  def add_attribution(props)
    # Gather
    attribution_data = {
      first_external_referrer:  get_first_referrer,
      latest_external_referrer: get_latest_referrer,
      latest_utm:               get_latest_utm
    }

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

  def get_latest_utm
    name    = params[:utm_campaign]
    source  = params[:utm_source]
    medium  = params[:utm_medium]
    term    = params[:utm_term]
    content = params[:utm_content]

    if name.blank?
      get_cookie 'latest_utm'
    else
      {
        name:     name,
        source:   source,
        medium:   medium,
        term:     term,
        content:  content
      }
    end
  end

  def attribution_host(url)
    return nil if url.nil?
    uri = URI.parse(url)
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
