# Require the airbrake gem in your App.
# ---------------------------------------------
#
# Ruby - In your Gemfile
# gem 'airbrake', '~> 5.0'
#
# Then add the following to config/initializers/errbit.rb
# -------------------------------------------------------

Airbrake.configure do |config|
  config.host = 'https://errbit.sumatosoft.com'
  config.project_id = 1
  config.project_key = 'f69ad37b372f0471c9dc3c44237e495c'

  # Uncomment for Rails apps
  # config.environment = Rails.env
  # config.ignore_environments = %w(development test)
end
