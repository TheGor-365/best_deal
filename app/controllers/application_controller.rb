class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  before_action :track_visit

  private

  def track_visit
    ahoy.track_visit
  end
end
