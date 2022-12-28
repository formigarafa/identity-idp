class SamlPostController < ApplicationController
  after_action -> { skip_cookie_if_needed }, only: :auth
  skip_before_action :verify_authenticity_token

  def auth
    path_year = request.path[-4..-1]
    path_method = "api_saml_authpost#{path_year}_url"
    action_url = Rails.application.routes.url_helpers.send(path_method)

    form_params = params.permit(:SAMLRequest, :RelayState, :SigAlg, :Signature)

    render 'shared/saml_post_form', locals: { action_url: action_url, form_params: form_params },
                                    layout: false
  end

  private

  def skip_cookie_if_needed
    analytics.track_event(
      "SAML POST Troubleshooting",
      session.to_json,
    )
    request.session_options[:skip] = true if user_signed_in?
  end
end
