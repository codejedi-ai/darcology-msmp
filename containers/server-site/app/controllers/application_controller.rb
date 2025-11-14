class ApplicationController < ActionController::Base
  def hello_world
    render plain: "Hello from #{ENV.fetch('RAILS_ENV')}!"
  end
end
