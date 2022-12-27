module Idv
  class VerifyPiiWaitController < ApplicationController
    include StepIndicatorConcern

    def show
      local_params = {
        step_template: "idv/doc_auth/verify_wait",
        flow_session: flow_session
      }
      render template: 'layouts/flow_step', locals: local_params
  end
end
