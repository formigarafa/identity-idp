module Idv
  class VerifyPiiController < ApplicationController
    # TODO Verify needed
    include StepIndicatorConcern

    def show
      local_params = {
        step_template: "" #what goes here?
      }
    end

    def confirm_idv_ssn_step_complete
      # TODO
    end

    def confirm_idv_doc_auth_complete
      # TODO
    end
  end
end
