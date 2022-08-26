require 'rails_helper'

RSpec.describe GetUspsProofingResultsJob do
  include UspsIppHelper

  let(:reprocess_delay_minutes) { 2.0 }
  let(:job) { GetUspsProofingResultsJob.new }
  let(:job_analytics) { FakeAnalytics.new }

  before do
    allow(job).to receive(:analytics).and_return(job_analytics)
    allow(IdentityConfig.store).to receive(:get_usps_proofing_results_job_reprocess_delay_minutes).
      and_return(reprocess_delay_minutes)
    stub_request_token
  end

  describe '#perform' do
    describe 'IPP enabled' do
      # these non-pending enrollments shouldn't be included when the job collects
      # enrollments that need their status checked
      let!(:establishing_enrollment) { create(:in_person_enrollment, :establishing) }
      let!(:expired_enrollment) { create(:in_person_enrollment, :expired) }
      let!(:failed_enrollment) { create(:in_person_enrollment, :failed) }
      let!(:passed_enrollment) { create(:in_person_enrollment, :passed) }

      let!(:pending_enrollments) do
        [
          create(:in_person_enrollment, :pending, selected_location_details: { name: 'BALTIMORE' }),
          create(
            :in_person_enrollment, :pending,
            selected_location_details: { name: 'FRIENDSHIP' }
          ),
          create(
            :in_person_enrollment, :pending,
            selected_location_details: { name: 'WASHINGTON' }
          ),
          create(:in_person_enrollment, :pending, selected_location_details: { name: 'ARLINGTON' }),
          create(:in_person_enrollment, :pending, selected_location_details: { name: 'DEANWOOD' }),
        ]
      end
      let(:pending_enrollment) { pending_enrollments[0] }

      before do
        allow(IdentityConfig.store).to receive(:in_person_proofing_enabled).and_return(true)
      end

      it 'requests the enrollments that need their status checked' do
        stub_request_passed_proofing_results

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).and_return([])

        job.perform(Time.zone.now)

        failure_message = 'expected call to InPersonEnrollment#needs_usps_status_check' \
          ' with beginless range starting about 5 minutes ago'
        expect(InPersonEnrollment).to(
          have_received(:needs_usps_status_check).
            with(
              satisfy do |v|
                v.begin.nil? && ((Time.zone.now - v.end) / 60).between?(
                  reprocess_delay_minutes - 0.25, reprocess_delay_minutes + 0.25
                )
              end,
            ),
          failure_message,
        )
      end

      it 'records the last attempted status check regardless of response code and contents' do
        stub_request_proofing_results_with_responses(
          request_failed_proofing_results_args,
          request_in_progress_proofing_results_args,
          request_in_progress_proofing_results_args,
          request_failed_proofing_results_args,
        )

        expect(pending_enrollments.pluck(:status_check_attempted_at)).to(
          all(eq nil),
          'failed test precondition: pending enrollments must not have status check time set',
        )

        start_time = Time.zone.now

        job.perform(Time.zone.now)

        expected_range = start_time...(Time.zone.now)

        failure_message = 'job must update status check time for all pending enrollments'
        expect(
          pending_enrollments.
            map(&:reload).
            pluck(:status_check_attempted_at),
        ).to(
          all(
            satisfy { |i| expected_range.cover?(i) },
          ),
          failure_message,
        )
      end

      it 'logs a message when the job starts' do
        stub_request_proofing_results_with_responses(
          request_failed_proofing_results_args,
          request_in_progress_proofing_results_args,
          request_in_progress_proofing_results_args,
          request_failed_proofing_results_args,
        )

        job.perform(Time.zone.now)

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Job started',
          enrollments_count: 5,
          reprocess_delay_minutes: 2.0,
        )
      end

      it 'logs a message with counts of various outcomes when the job completes' do
        stub_request_proofing_results_with_responses(
          request_passed_proofing_results_args,
          request_in_progress_proofing_results_args,
          { status: 500 },
          request_failed_proofing_results_args,
          request_expired_proofing_results_args,
        )

        job.perform(Time.zone.now)

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Job completed',
          enrollments_checked: 5,
          enrollments_errored: 1,
          enrollments_expired: 1,
          enrollments_failed: 1,
          enrollments_in_progress: 1,
          enrollments_passed: 1,
        )
      end

      it 'logs details about a failed proofing' do
        stub_request_failed_proofing_results

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        job.perform(Time.zone.now)

        pending_enrollment.reload

        expect(pending_enrollment.failed?).to be_truthy

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Enrollment status updated',
          enrollment_code: pending_enrollment.enrollment_code,
          enrollment_id: pending_enrollment.id,
          failure_reason: 'Clerk indicates that ID name or address does not match source data.',
          fraud_suspected: false,
          passed: false,
          primary_id_type: 'Uniformed Services identification card',
          proofing_state: 'PA',
          reason: 'Failed status',
          secondary_id_type: 'Deed of Trust',
          transaction_end_date_time: '12/17/2020 034055',
          transaction_start_date_time: '12/17/2020 033855',
        )
      end

      it 'logs status check timing details about the enrollments' do
        stub_request_failed_proofing_results
        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        pending_enrollment.update(
          status_check_attempted_at: (Time.zone.now - 15.minutes),
          status_updated_at: (Time.zone.now - 2.days),
        )

        job.perform(Time.zone.now)

        pending_enrollment.reload

        expect(
          job_analytics.events['GetUspsProofingResultsJob: Enrollment status updated'].
                         first[:minutes_since_last_status_check],
        ).to be_within(0.01).of(15.0)
        expect(
          job_analytics.events['GetUspsProofingResultsJob: Enrollment status updated'].
                         first[:minutes_since_last_status_update],
        ).to be_within(0.01).of(2880)
        expect(
          job_analytics.events['GetUspsProofingResultsJob: Enrollment status updated'].
                         first[:minutes_to_completion],
        ).to be_instance_of(Float)
      end

      describe 'sending emails' do
        it 'sends proofing failed email on response with failed status' do
          stub_request_failed_proofing_results

          allow(InPersonEnrollment).to receive(:needs_usps_status_check).
            and_return([pending_enrollment])

          mailer = instance_double(ActionMailer::MessageDelivery, deliver_now_or_later: true)
          user = pending_enrollment.user
          user.email_addresses.each do |email_address|
            # it sends with the default delay
            expect(mailer).to receive(:deliver_now_or_later).with(wait: 1.hour)
            expect(UserMailer).to receive(:in_person_failed).
              with(
                user,
                email_address,
                enrollment: instance_of(InPersonEnrollment),
              ).
              and_return(mailer)
          end

          job.perform(Time.zone.now)
        end

        it 'sends proofing verifed email on 2xx responses with valid JSON' do
          stub_request_passed_proofing_results

          allow(InPersonEnrollment).to receive(:needs_usps_status_check).
            and_return([pending_enrollment])

          mailer = instance_double(ActionMailer::MessageDelivery, deliver_now_or_later: true)
          user = pending_enrollment.user
          user.email_addresses.each do |email_address|
            # it sends with the default delay
            expect(mailer).to receive(:deliver_now_or_later).with(wait: 1.hour)
            expect(UserMailer).to receive(:in_person_verified).
              with(
                user,
                email_address,
                enrollment: instance_of(InPersonEnrollment),
              ).
              and_return(mailer)
          end

          job.perform(Time.zone.now)
        end

        context 'a custom delay greater than zero is set' do
          it 'uses the custom delay' do
            stub_request_passed_proofing_results

            allow(IdentityConfig.store).
              to(receive(:in_person_results_delay_in_hours).and_return(5))

            allow(InPersonEnrollment).to receive(:needs_usps_status_check).
              and_return([pending_enrollment])

            mailer = instance_double(ActionMailer::MessageDelivery, deliver_now_or_later: true)
            user = pending_enrollment.user
            user.email_addresses.each do |email_address|
              expect(mailer).to receive(:deliver_now_or_later).with(wait: 5.hours)
              expect(UserMailer).to receive(:in_person_verified).and_return(mailer)
            end

            job.perform(Time.zone.now)
          end
        end

        context 'a custom delay of zero is set' do
          it 'does not delay sending the email' do
            stub_request_passed_proofing_results

            allow(IdentityConfig.store).
              to(receive(:in_person_results_delay_in_hours).and_return(0))

            allow(InPersonEnrollment).to receive(:needs_usps_status_check).
              and_return([pending_enrollment])

            mailer = instance_double(ActionMailer::MessageDelivery, deliver_now_or_later: true)
            user = pending_enrollment.user
            user.email_addresses.each do |email_address|
              expect(mailer).to receive(:deliver_now_or_later).with(no_args)
              expect(UserMailer).to receive(:in_person_verified).and_return(mailer)
            end

            job.perform(Time.zone.now)
          end
        end
      end

      it 'updates enrollment records and activates profiles on response with passed status' do
        stub_request_passed_proofing_results

        start_time = Time.zone.now

        job.perform(Time.zone.now)

        expected_range = start_time...(Time.zone.now)

        pending_enrollments.each do |enrollment|
          enrollment.reload
          expect(enrollment.passed?).to be_truthy
          expect(enrollment.status_updated_at).to satisfy do |timestamp|
            expected_range.cover?(timestamp)
          end
          expect(enrollment.profile.active).to be(true)

          expect(job_analytics).to have_logged_event(
            'GetUspsProofingResultsJob: Enrollment status updated',
            enrollment_code: enrollment.enrollment_code,
            enrollment_id: enrollment.id,
            fraud_suspected: false,
            passed: true,
            reason: 'Successful status update',
          )
        end
      end

      it 'receives a non-hash value' do
        stub_request_proofing_results_with_responses({})

        job.perform(Time.zone.now)

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Exception raised',
          reason: 'Bad response structure',
          enrollment_id: pending_enrollment.id,
          enrollment_code: pending_enrollment.enrollment_code,
        )
      end

      it 'receives an unsupported status' do
        stub_request_passed_proofing_unsupported_status_results

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        job.perform(Time.zone.now)

        pending_enrollment.reload

        expect(pending_enrollment.pending?).to be_truthy

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Exception raised',
          enrollment_code: pending_enrollment.enrollment_code,
          enrollment_id: pending_enrollment.id,
          reason: 'Unsupported status',
          status: 'Not supported',
        )
      end

      it 'reports a high-priority error on 2xx responses with invalid JSON' do
        stub_request_proofing_results_with_invalid_response

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        job.perform(Time.zone.now)

        pending_enrollment.reload

        expect(pending_enrollment.pending?).to be_truthy

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Exception raised',
          reason: 'Request exception',
          enrollment_id: pending_enrollment.id,
          enrollment_code: pending_enrollment.enrollment_code,
        )
      end

      it 'reports a low-priority error on 4xx responses' do
        stub_request_proofing_results_with_responses({ status: 400 })

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        job.perform(Time.zone.now)

        pending_enrollment.reload

        expect(pending_enrollment.pending?).to be_truthy

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Exception raised',
          reason: 'Request exception',
          enrollment_id: pending_enrollment.id,
          enrollment_code: pending_enrollment.enrollment_code,
        )
      end

      it 'marks enrollments as expired when USPS says they have expired' do
        stub_request_expired_proofing_results

        job.perform(Time.zone.now)

        pending_enrollments.each do |enrollment|
          enrollment.reload
          expect(enrollment.expired?).to be_truthy
        end
      end

      it 'ignores enrollments when USPS says the customer has not been to the post office' do
        stub_request_in_progress_proofing_results

        job.perform(Time.zone.now)

        pending_enrollments.each do |enrollment|
          enrollment.reload
          expect(enrollment.pending?).to be_truthy
        end
      end

      it 'reports a high-priority error on 5xx responses' do
        stub_request_proofing_results_with_responses({ status: 500 })

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        job.perform(Time.zone.now)

        pending_enrollment.reload

        expect(pending_enrollment.pending?).to be_truthy

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Exception raised',
          reason: 'Request exception',
          enrollment_id: pending_enrollment.id,
          enrollment_code: pending_enrollment.enrollment_code,
        )
      end

      it 'fails enrollment for unsupported ID types' do
        stub_request_passed_proofing_unsupported_id_results

        allow(InPersonEnrollment).to receive(:needs_usps_status_check).
          and_return([pending_enrollment])

        expect(pending_enrollment.pending?).to be_truthy

        job.perform Time.zone.now

        expect(pending_enrollment.reload.failed?).to be_truthy

        expect(job_analytics).to have_logged_event(
          'GetUspsProofingResultsJob: Enrollment status updated',
          enrollment_code: pending_enrollment.enrollment_code,
          enrollment_id: pending_enrollment.id,
          fraud_suspected: false,
          passed: false,
          primary_id_type: 'Not supported',
          reason: 'Unsupported ID type',
        )
      end
    end

    describe 'IPP disabled' do
      before do
        allow(IdentityConfig.store).to receive(:in_person_proofing_enabled).and_return(false)
        allow(IdentityConfig.store).to receive(:usps_mock_fallback).and_return(false)
      end

      it 'does not request any enrollment records' do
        # no stubbing means this test will fail if the UspsInPersonProofing::Proofer
        # tries to connect to the USPS API
        job.perform Time.zone.now
      end
    end
  end
end
