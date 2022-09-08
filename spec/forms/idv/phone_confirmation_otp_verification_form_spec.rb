require 'rails_helper'

describe Idv::PhoneConfirmationOtpVerificationForm do
  let(:user) { create(:user, :signed_up) }
  let(:phone) { '+1 (225) 555-5000' }
  let(:phone_confirmation_otp_sent_at) { Time.zone.now }
  let(:phone_confirmation_otp_code) { '123456' }
  let(:user_phone_confirmation_session) do
    PhoneConfirmation::ConfirmationSession.new(
      code: phone_confirmation_otp_code,
      phone: phone,
      sent_at: phone_confirmation_otp_sent_at,
      delivery_method: :sms,
    )
  end
  let(:irs_attempts_api_tracker) do
    instance_double(
      IrsAttemptsApi::Tracker,
      idv_phone_otp_submitted_rate_limited: true,
    )
  end

  describe '#submit' do
    def try_submit(code)
      described_class.new(
        user: user,
        user_phone_confirmation_session: user_phone_confirmation_session,
        irs_attempts_api_tracker: irs_attempts_api_tracker,
      ).submit(code: code)
    end

    context 'when the code matches' do
      it 'returns a successful result' do
        result = try_submit(phone_confirmation_otp_code)

        expect(result.success?).to eq(true)
      end

      it 'clears the second factor attempts' do
        user.update(second_factor_attempts_count: 4)

        try_submit(phone_confirmation_otp_code)

        expect(user.reload.second_factor_attempts_count).to eq(0)
      end
    end

    context 'when the code does not match' do
      it 'returns an unsuccessful result' do
        result = try_submit('xxxxxx')

        expect(result.success?).to eq(false)
      end

      it 'increments second factor attempts' do
        2.times do
          try_submit('xxxxxx')
        end

        user.reload

        expect(user.second_factor_attempts_count).to eq(2)
        expect(user.second_factor_locked_at).to eq(nil)

        try_submit('xxxxxx')

        expect(user.second_factor_attempts_count).to eq(3)
        expect(user.second_factor_locked_at).to be_within(1.second).of(Time.zone.now)
      end
    end

    context 'when the code is expired' do
      let(:phone_confirmation_otp_sent_at) { 11.minutes.ago }

      before do
        allow(IrsAttemptsApi::Tracker).to receive(:new).and_return(irs_attempts_api_tracker)
      end

      it 'returns an unsuccessful result' do
        result = try_submit(phone_confirmation_otp_code)

        expect(result.success?).to eq(false)
      end

      it 'increment second factor attempts and locks out user after too many' do
        2.times do
          try_submit(phone_confirmation_otp_code)
        end

        user.reload

        expect(user.second_factor_attempts_count).to eq(2)
        expect(user.second_factor_locked_at).to eq(nil)

        try_submit(phone_confirmation_otp_code)

        expect(user.second_factor_attempts_count).to eq(3)
        expect(user.second_factor_locked_at).to be_within(1.second).of(Time.zone.now)
        expect(irs_attempts_api_tracker).to have_received(:idv_phone_otp_submitted_rate_limited)
      end
    end

    it 'handles nil and empty codes' do
      result = try_submit(nil)

      expect(result.success?).to eq(false)

      result = try_submit('')

      expect(result.success?).to eq(false)
    end
  end
end
