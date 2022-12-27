module Idv
  module VerifyPiiConcern
    extend ActiveSupport::Concern

    included do
      helper_method :process_async_state
      helper_method :async_state_done
      helper_method :async_state
      helper_method :add_proofing_costs
      helper_method :process_aamva
      helper_method :track_aamva
      helper_method :idv_success
      helper_method :idv_errors
      helper_method :idv_extra
      helper_method :check_ssn
      helper_method :save_legacy_state
      helper_method :skip_legacy_steps

      # TODO: Could these go elsewhere?
      helper_method :pii
      helper_method :idv_result_to_form_response
      helper_method :redact
    end

    def check_ssn
      result = Idv::SsnForm.new(current_user).submit(ssn: pii[:ssn])

      if result.success?
        save_legacy_state
        delete_pii
      end

      result
    end

    def save_legacy_state
      skip_legacy_steps
      idv_session['applicant'] = pii
      idv_session['applicant']['uuid'] = current_user.uuid
    end

    def skip_legacy_steps
      idv_session['profile_confirmation'] = true
      idv_session['vendor_phone_confirmation'] = false
      idv_session['user_phone_confirmation'] = false
      idv_session['address_verification_mechanism'] = 'phone'
      idv_session['resolution_successful'] = 'phone'
    end

    def idv_success(idv_result)
      idv_result[:success]
    end

    def idv_errors(idv_result)
      idv_result[:errors]
    end

    def idv_extra(idv_result)
      idv_result.except(:errors, :success)
    end

    def redact(text)
      text.gsub(/[a-z]/i, 'X').gsub(/\d/i, '#')
    end

    def idv_result_to_form_response(
      result:,
      state: nil,
      state_id_jurisdiction: nil,
      state_id_number: nil,
      extra: {}
    )
      state_id = result.dig(:context, :stages, :state_id)
      if state_id
        state_id[:state] = state if state
        state_id[:state_id_jurisdiction] = state_id_jurisdiction if state_id_jurisdiction
        state_id[:state_id_number] = redact(state_id_number) if state_id_number
      end
      FormResponse.new(
        success: idv_success(result),
        errors: idv_errors(result),
        extra: extra.merge(proofing_results: idv_extra(result)),
      )
    end

    def pii
      flow_session[:pii_from_doc]
    end

    def process_aamva(transaction_id)
      # transaction_id comes from TransactionLocatorId
      add_cost(:aamva, transaction_id: transaction_id)
      track_aamva
    end

    def track_aamva
      return unless IdentityConfig.store.state_tracking_enabled
      doc_auth_log = DocAuthLog.find_by(user_id: user_id)
      return unless doc_auth_log
      doc_auth_log.aamva = true
      doc_auth_log.save!
    end

    def add_proofing_costs(results)
      results[:context][:stages].each do |stage, hash|
        if stage == :resolution
          # transaction_id comes from ConversationId
          add_cost(:lexis_nexis_resolution, transaction_id: hash[:transaction_id])
        elsif stage == :state_id
          next if hash[:vendor_name] == 'UnsupportedJurisdiction'
          process_aamva(hash[:transaction_id])
        elsif stage == :threatmetrix
          # transaction_id comes from request_id
          tmx_id = hash[:transaction_id]
          add_cost(:threatmetrix, transaction_id: tmx_id) if tmx_id
        end
      end
    end
    
    def process_async_state(current_async_state)
      if current_async_state.none?
        mark_step_incomplete(:verify)
      elsif current_async_state.in_progress?
        nil
      elsif current_async_state.missing?
        flash[:error] = I18n.t('idv.failure.timeout')
        delete_async
        mark_step_incomplete(:verify)
        analytics.idv_proofing_resolution_result_missing
      elsif current_async_state.done?
        async_state_done(current_async_state)
      end
    end

    def async_state_done(current_async_state)
      add_proofing_costs(current_async_state.result)
      form_response = idv_result_to_form_response(
        result: current_async_state.result,
        state: pii[:state],
        state_id_jurisdiction: pii[:state_id_jurisdiction],
        state_id_number: pii[:state_id_number],
        # todo: add other edited fields?
        extra: {
          address_edited: !!flow_session['address_edited'],
          pii_like_keypaths: [[:errors, :ssn], [:response_body, :first_name]],
        },
      )
      pii_from_doc = pii || {}
      irs_attempts_api_tracker.idv_verification_submitted(
        success: form_response.success?,
        document_state: pii_from_doc[:state],
        document_number: pii_from_doc[:state_id_number],
        document_issued: pii_from_doc[:state_id_issued],
        document_expiration: pii_from_doc[:state_id_expiration],
        first_name: pii_from_doc[:first_name],
        last_name: pii_from_doc[:last_name],
        date_of_birth: pii_from_doc[:dob],
        address: pii_from_doc[:address1],
        ssn: pii_from_doc[:ssn],
        failure_reason: irs_attempts_api_tracker.parse_failure_reason(form_response),
      )

      if form_response.success?
        response = check_ssn
        form_response = form_response.merge(response)
      end
      summarize_result_and_throttle_failures(form_response)
      delete_async

      if form_response.success?
        mark_step_complete(:verify_wait)
      else
        mark_step_incomplete(:verify)
      end

      form_response
    end

    def async_state
      dcs_uuid = flow_session[verify_step_document_capture_session_uuid_key]
      dcs = DocumentCaptureSession.find_by(uuid: dcs_uuid)
      return ProofingSessionAsyncResult.none if dcs_uuid.nil?
      return ProofingSessionAsyncResult.missing if dcs.nil?

      proofing_job_result = dcs.load_proofing_result
      return ProofingSessionAsyncResult.missing if proofing_job_result.nil?

      proofing_job_result
    end
    
  end
end
