module Idv
  class VerifyPiiWaitController < ApplicationController
#    include IdvStepConcern
    include StepIndicatorConcern
    include VerifyPiiConcern

    def show
      local_params = {
        meta_refresh = 600
      }
      render template: "verify_wait", locals: local_params
    end
  end
end