Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resources :passwords, param: :token, only: %i[new create edit update]

  root "dashboards#show"

  # guru_mapel
  resources :kits do
    member do
      post :duplicate
      get :worksheet
    end
  end

  resources :results, only: %i[index show]

  # wakil_kurikulum
  namespace :curriculum do
    root "dashboards#show"
    resource :school, only: %i[show update]
    resources :periods, except: :show
    resources :school_classes, except: :show
    resources :subjects, except: :show
    resources :lessons, except: :show
    resources :duty_assignments, only: %i[index create destroy]
    resources :absences, only: %i[new create]
  end

  # guru_piket
  namespace :duty do
    root "activations#index"
    resources :activations, only: :show do
      member do
        get :worksheet
        patch :complete
      end
      resources :attendance_records, only: :update
      resources :submissions, only: :update
    end
  end

  # kepala_sekolah (+ wakil_kurikulum)
  resources :reports, only: %i[index show]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
