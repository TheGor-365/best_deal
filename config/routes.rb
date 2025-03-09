Rails.application.routes.draw do
  root 'search#index'
  
  get 'search/index'
  get 'search/results'
  get 'search/info'
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
