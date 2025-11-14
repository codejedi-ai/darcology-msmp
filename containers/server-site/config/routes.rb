Rails.application.routes.draw do
  root "dashboard#index"
  get '/stats', to: 'dashboard#stats'
  get '/cpu', to: 'dashboard#cpu'
  get '/memory', to: 'dashboard#memory'
  get '/player_sessions', to: 'dashboard#player_sessions'
  get '/download_mods', to: 'dashboard#download_mods'
end
