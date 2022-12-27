module Idv
  class VerifyPiiWaitController < ApplicationController
    include StepIndicatorConcern

    def show
      local_params = {
        step_url: method(:idv_doc_auth_verify_pii_wait_url),
        step_template: "idv/doc_auth/verify_wait",
        flow_session: flow_session
      }
      render template: 'layouts/flow_step', locals: local_params
    end

    def create
      redirect_to idv_review_url
    end

    # copied from doc_auth_controller
    def flow_session
      user_session['idv/doc_auth']
    end


  end
end
