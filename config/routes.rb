Rails.application.routes.draw do

  get 'events', to: 'events#index'
  post 'events', to: 'events#create'
  delete 'events', to: 'events#delete'

  get 'api/authorize'
  get 'api/callback'
  post 'api/alexa_endpoint'
  post 'api/set_day_times'

  get 'api/test'

end
