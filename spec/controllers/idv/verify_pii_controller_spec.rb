require 'rails_helper'

describe Idv::VerifyPiiController do
    let(:user) { build(:user) }
  let(:service_provider) do
    create(
      :service_provider,
      issuer: 'http://sp.example.com',
      app_id: '123',
    )
  end
  let(:request) do
    double(
      'request',
      remote_ip: Faker::Internet.ip_v4_address,
      headers: { 'X-Amzn-Trace-Id' => amzn_trace_id },
    )
  end
  # let(:controller) do
  #   instance_double(
  #     'controller',
  #     session: { sp: { issuer: service_provider.issuer } },
  #     current_user: user,
  #     analytics: FakeAnalytics.new,
  #     url_options: {},
  #     request: request,
  #   )
  # end
  let(:amzn_trace_id) { SecureRandom.uuid }

  let(:pii_from_doc) do
    {
      ssn: '123-45-6789',
      first_name: 'bob',
    }
  end

  describe '#show' do
    it 'exists' do
      binding.pry
      subject.show
    end
  end
end
