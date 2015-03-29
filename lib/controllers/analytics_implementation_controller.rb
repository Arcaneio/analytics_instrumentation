class AnalyticsImplementationController < ApplicationController

  # Exposes an endpoint to which one can ajax handwritten events.
  def analytics_event
    name = params[:name]
    properties = params[:properties]
    analyticsTrackEvent(name, properties)
    render text: ""
  end

end
