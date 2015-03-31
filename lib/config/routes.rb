Rails.application.routes.draw do

  post "api/analytics_event" => "analytics_implementation#analytics_event", as: :analytics_event

end
