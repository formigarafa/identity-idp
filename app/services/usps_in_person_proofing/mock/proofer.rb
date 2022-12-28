module UspsInPersonProofing
  module Mock
    class Proofer
      def request_enroll(applicant)
        case applicant['first_name']
        when 'usps waiting'
          # timeout
          raise Faraday::TimeoutError.new
        when 'usps client error'
          # usps 400 response
          body = JSON.parse(Fixtures.request_enroll_bad_request_response)
          response = { body: body, status: 400 }
          raise Faraday::BadRequestError.new('Bad request error', response)
        when 'usps server error'
          # usps 500 response
          body = JSON.parse(Fixtures.internal_server_error_response)
          response = { body: body, status: 500 }
          raise Faraday::ServerError.new('Internal server error', response)
        when 'usps invalid response'
          # no enrollment code
          res = JSON.parse(Fixtures.request_enroll_invalid_response)
        else
          # success
          res = JSON.parse(Fixtures.request_enroll_response)
        end

        Response::RequestEnrollResponse.new(res)
      end

      def request_facilities(_location)
        parse_facilities(JSON.parse(Fixtures.request_facilities_response))
      end

      def parse_facilities(facilities)
        facilities['postOffices'].map do |post_office|
          hours = {}
          post_office['hours'].each do |hour_details|
            hour_details.keys.each do |key|
              hours[key] = hour_details[key]
            end
          end

          PostOffice.new(
            address: post_office['streetAddress'],
            city: post_office['city'],
            distance: post_office['distance'],
            name: post_office['name'],
            phone: post_office['phone'],
            saturday_hours: hours['saturdayHours'],
            state: post_office['state'],
            sunday_hours: hours['sundayHours'],
            weekday_hours: hours['weekdayHours'],
            zip_code_4: post_office['zip4'],
            zip_code_5: post_office['zip5'],
          )
        end
      end

      def request_pilot_facilities
        JSON.load_file(
          Rails.root.join(
            'config',
            'ipp_pilot_usps_facilities.json',
          ),
        )
      end
    end
  end
end
