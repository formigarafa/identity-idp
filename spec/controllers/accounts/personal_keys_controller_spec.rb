require 'rails_helper'

RSpec.describe Accounts::PersonalKeysController do
  describe '#create' do
    it 'generates a new personal key, tracks an analytics event, and redirects' do
      stub_sign_in(create(:user, :with_phone))
      stub_analytics

      generator = instance_double(PersonalKeyGenerator)
      allow(PersonalKeyGenerator).to receive(:new).
        with(subject.current_user).and_return(generator)

      expect(generator).to receive(:create)
      expect(@analytics).to receive(:track_event).with(Analytics::PROFILE_PERSONAL_KEY_CREATE)
      expect(@analytics).to receive(:track_event).with(
        Analytics::PROFILE_PERSONAL_KEY_CREATE_NOTIFICATIONS,
        hash_including(emails: 1, sms_message_ids: ['fake-message-id']),
      )

      post :create

      expect(response).to redirect_to manage_personal_key_path
    end

    it 'tracks CSRF errors' do
      stub_sign_in
      stub_analytics
      analytics_hash = {
        controller: 'accounts/personal_keys#create',
        user_signed_in: true,
      }
      allow(controller).to receive(:create).and_raise(ActionController::InvalidAuthenticityToken)

      expect(@analytics).to receive(:track_event).
        with(Analytics::INVALID_AUTHENTICITY_TOKEN, analytics_hash)

      post :create

      expect(response).to redirect_to new_user_session_url
      expect(flash[:error]).to eq t('errors.invalid_authenticity_token')
    end
  end
end
