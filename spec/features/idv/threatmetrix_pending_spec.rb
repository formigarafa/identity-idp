require 'rails_helper'

RSpec.feature 'Users pending threatmetrix review', :js do
  include IdvStepHelper

  before do
    allow(IdentityConfig.store).to receive(:proofing_device_profiling).and_return(:enabled)
    allow(IdentityConfig.store).to receive(:lexisnexis_threatmetrix_org_id).and_return('test_org')
  end

  scenario 'users pending threatmetrix see sad face screen and cannot perform idv' do
    allow(IdentityConfig.store).to receive(:otp_delivery_blocklist_maxretry).and_return(300)
    user = create(:user, :signed_up)

    start_idv_from_sp
    sign_in_and_2fa_user(user)
    complete_doc_auth_steps_before_ssn_step
    select 'Reject', from: :mock_profiling_result
    complete_ssn_step
    click_idv_continue
    complete_phone_step(user)
    complete_review_step(user)
    acknowledge_and_confirm_personal_key

    expect(page).to have_content(t('idv.failure.setup.heading'))
    expect(page).to have_current_path(idv_setup_errors_path)

    # User unable to sign into OIDC with IdV
    set_new_browser_session
    start_idv_from_sp(:oidc)
    sign_in_live_with_2fa(user)

    expect(page).to have_content(t('idv.failure.setup.heading'))
    expect(page).to have_current_path(idv_setup_errors_path)

    # User unable to sign into SAML with IdV
    set_new_browser_session
    start_idv_from_sp(:saml)
    sign_in_live_with_2fa(user)

    expect(page).to have_content(t('idv.failure.setup.heading'))
    expect(page).to have_current_path(idv_setup_errors_path)

    # User able to sign for IAL1
    set_new_browser_session
    visit_idp_from_sp_with_ial1(:oidc)
    sign_in_live_with_2fa(user)
    click_agree_and_continue

    expect(current_path).to eq('/auth/result')
  end
end
