module Idv
  class VerifyPiiWaitShowController < ApplicationController
#    include IdvStepConcern
    include StepIndicatorConcern
    include VerifyPiiConcern

    # def show
    #   local_params = {
    #     step_url: method(:idv_doc_auth_verify_pii_wait_show_url),
    #     step_template: "idv/doc_auth/verify_wait",
    #     flow_session: flow_session
    #   }

    #   call
    #   render template: 'layouts/flow_step', locals: local_params
    # end

    def call
      poll_with_meta_refresh(IdentityConfig.store.poll_rate_for_verify_in_seconds)

      process_async_state(async_state)
    end

    def poll_with_meta_refresh(seconds)
      @meta_refresh = seconds
    end

    # copied from doc_auth_controller
    def flow_session
      user_session['idv/doc_auth']
    end

    # copied from doc_auth_base_step
    def verify_step_document_capture_session_uuid_key
      :idv_verify_step_document_capture_session_uuid
    end

    # copied from doc_auth_base_step
    def add_cost(token, transaction_id: nil)
      Db::SpCost::AddSpCost.call(current_sp, 2, token, transaction_id: transaction_id)
    end

    # copied from doc_auth_base_step
    def user_id_from_token
      flow_session[:doc_capture_user_id]
    end

    # copied from doc_auth_base_step
    def user_id
      current_user ? current_user.id : user_id_from_token
    end
  end
end
