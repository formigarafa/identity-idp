module Idv
  class VerifyPiiController < ApplicationController
    # TODO Verify needed
    include StepIndicatorConcern

    def show
      local_params = {
        pii: pii,
        step_url: method(:idv_doc_auth_verify_pii_url),
        step_template: "idv/doc_auth/verify",
        flow_session: flow_session
      }

      render template: 'layouts/flow_step', locals: local_params
    end

    def confirm_idv_ssn_step_complete
      # TODO
    end

    def confirm_idv_doc_auth_complete
      # TODO
    end

    # copied from doc_auth_controller
    def flow_session
      user_session['idv/doc_auth']
    end


    # copied from verify_step
    def pii
      flow_session[:pii_from_doc]
    end

    def call
      enqueue_job
    end


  end
end
