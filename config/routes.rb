Rails.application.routes.draw do

  post 'api/alexa_endpoint'
  get 'api/authorize'
  get 'api/callback'
  get 'api/calendars'
  get 'api/events'
  get 'api/new_event'

end
