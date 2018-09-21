class ApiController < ApplicationController

    def authorize
        client = Signet::OAuth2::Client.new(client_options)
        redirect_to client.authorization_uri.to_s
    end

    def callback
        client = Signet::OAuth2::Client.new(client_options)
        client.code = params[:code]

        response = client.fetch_access_token!
        tokens = {
            response: response,
            code: params[:code]
        }

        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end

        redirect_to api_calendars_url
    end

    def calendars
        client = Signet::OAuth2::Client.new(client_options)
        google_tokens = File.read('./google_tokens.json')
        tokens = JSON.parse(google_tokens)
        client.code = tokens['code']
        client.update!(tokens['response'])

        service = Google::Apis::CalendarV3::CalendarService.new
        service.authorization = client

        @calendar_list = service.list_calendar_lists

        render :json => {
            calendars: @calendar_list
        }

    rescue Google::Apis::AuthorizationError
        response = client.refresh!
        tokens['response'] = response
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end
        retry
    end

    def events
        # connect to API
        client = Signet::OAuth2::Client.new(client_options)
        google_tokens = File.read('./google_tokens.json')
        tokens = JSON.parse(google_tokens)
        client.update!(tokens['response'])

        service = Google::Apis::CalendarV3::CalendarService.new
        service.authorization = client

        # determine query time
        timeStart = Time.now.iso8601;
        timeEnd = (Time.now + (60 * 60 * 24 * 2)).iso8601

        # get events
        @event_list = service.list_events(
            'primary',
            single_events: true,
            order_by: 'startTime',
            time_min: timeStart,
            time_max: timeEnd)

        @event_list = @event_list.items

        render :json => {
            events: @event_list
        }

    rescue Google::Apis::AuthorizationError
        response = client.refresh!
        tokens['response'] = response
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end
        retry
    end

    def new_event
        # connect to API
        client = Signet::OAuth2::Client.new(client_options)
        google_tokens = File.read('./google_tokens.json')
        tokens = JSON.parse(google_tokens)
        client.update!(tokens['response'])

        service = Google::Apis::CalendarV3::CalendarService.new
        service.authorization = client

        time = DateTime.now
        startTime = time + Rational(1, 24)
        endTime = time + Rational(2, 24)
        puts startTime

        event = Google::Apis::CalendarV3::Event.new({
            start: Google::Apis::CalendarV3::EventDateTime.new(date_time: startTime),
            end: Google::Apis::CalendarV3::EventDateTime.new(date_time: endTime),
            summary: 'New event!'
        })

        service.insert_event('primary', event)

        redirect_to api_events_url

    rescue Google::Apis::AuthorizationError
        response = client.refresh!
        tokens['response'] = response
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end
        retry
    end


    private

    def client_options
        {
            client_id: Rails.application.secrets.google_client_id,
            client_secret: Rails.application.secrets.google_client_secret,
            authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
            token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
            scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
            redirect_uri: 'http://localhost:3000/api/callback'
        }
    end

end
