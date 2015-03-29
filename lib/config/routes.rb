# TODO: Not namespace this

CanopyBackend::Application.routes.draw do

  post "api/analytics_event" => "analytics_implementation#analytics_event", as: :analytics_event

end
