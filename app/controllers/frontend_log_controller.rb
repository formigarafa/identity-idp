class FrontendLogController < ApplicationController
  respond_to :json

  skip_before_action :verify_authenticity_token
  before_action :check_user_authenticated
  before_action :validate_parameter_types

  EVENT_MAP = {
    'IdV: personal key visited' => :idv_personal_key_visited,
    'IdV: personal key confirm visited' => :idv_personal_key_confirm_visited,
    'IdV: personal key submitted' => :idv_personal_key_submitted,
  }.transform_values { |method| AnalyticsEvents.instance_method(method) }.freeze

  def create
    event = log_params[:event]
    payload = log_params[:payload].to_h
    if EVENT_MAP.key?(event)
      EVENT_MAP[event].bind_call(analytics, **payload)
    else
      analytics.track_event("Frontend: #{event}", payload)
    end

    render json: { success: true }, status: :ok
  end

  private

  def log_params
    params.permit(:event, payload: {})
  end

  def check_user_authenticated
    return if effective_user

    render json: { success: false }, status: :unauthorized
  end

  def validate_parameter_types
    return if valid_event? && valid_payload?

    render json: { success: false, error_message: 'invalid parameters' },
           status: :bad_request
  end

  def valid_event?
    log_params[:event].is_a?(String) &&
      log_params[:event].present?
  end

  def valid_payload?
    !log_params[:payload].nil?
  end
end
