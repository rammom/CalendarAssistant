require 'ralyxa'

class ApiController < ApplicationController

    # Connect google calendar account with app
    def authorize
        client = Signet::OAuth2::Client.new(client_options)
        redirect_to client.authorization_uri.to_s
    end

    # After authorization setup, exchange auth code for access token & save
    def callback
        client = Signet::OAuth2::Client.new(client_options)
        client.code = params[:code]

        response = client.fetch_access_token!
        tokens = {
            response: response,
            code: params[:code]
        }

        # save token to file
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end

        render :json => {
            "status": "All set"
        }
    end

    # Handles all requests coming from alexa, redirects to corresponding intent
    def alexa_endpoint
        p "here"
        render :json => Ralyxa::Skill.handle(request)
    end

    # Change day start and end times for scheduling
    def set_day_times

        start_time = params[:anything]["start"]
        end_time = params[:anything]["end"]

        if (/^\d+$/.match(start_time) && /^\d+$/.match(end_time) && start_time.to_i < end_time.to_i && start_time.to_i >= 0 && end_time.to_i <= 23)
            # save times to file
            File.open('./day_times_config.json', 'w') do |f|
                f.write(params[:anything].to_json);
            end
        end

        redirect_to events_url
    end

    def test
        client_options = Utils::get_client_options()

        # convert date string to DateTime object 
        #date = Utils::string_to_dateTime(request.slot_value("date"))

        # setup google outh2 authentication & connect to calendar
        service = Utils::connect_google_calendar()

        # set start and end times to strings one day apart
        start_time = (DateTime.now).iso8601
        end_time = (DateTime.now + 7).iso8601

        # query for calendar events
        event_list = service.list_events(
            'primary',
            single_events: true,
            order_by: 'starttime',
            time_min: start_time,
            time_max: end_time
        )

        # map events to more alexa speech friendly objects
        #events = []
        #event_list = event_list.items

        render :json => event_list
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
