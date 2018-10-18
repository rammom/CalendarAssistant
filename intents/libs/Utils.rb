module Utils

    def Utils.get_client_options()
        return {
            client_id: Rails.application.secrets.google_client_id,
            client_secret: Rails.application.secrets.google_client_secret,
            authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
            token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
            scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
            redirect_uri: 'http://localhost:3000/api/callback'
        }
    end

    # Exchange authorization code for a google access token
    def Utils.connect_google_calendar()
        # setup google outh2 authentication
        client = Signet::OAuth2::Client.new(Utils.get_client_options())     # initialize client
        google_tokens = File.read('./google_tokens.json')
        tokens = JSON.parse(google_tokens)
        client.code = tokens['code']
        client.update!(tokens['response'])          # add our access token to the client

        # save token
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end

        # connect to google calendar API
        service = Google::Apis::CalendarV3::CalendarService.new
        service.authorization = client

        return service
    end

    # use google refresh token to request new access token after expiry
    def Utils.refresh_google_client()
    
        client = Signet::OAuth2::Client.new(Utils.get_client_options())     # initialize client
        google_tokens = File.read('./google_tokens.json')
        tokens = JSON.parse(google_tokens)
        client.code = tokens['code']
        tokens['response'] = client.refresh!
        
        # save token
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end

    end

    def Utils.build_alexa_response(str)
        return {
            "version": "1.0",
            "response": {
                "outputSpeech": {
                    "type": "PlainText",
                    "text": str
                },
                "shouldEndSession": true
            }
        }
    end

    # convert date string to DateTime object
    def Utils.string_to_dateTime(str)
        date = DateTime.parse(str).beginning_of_day
        date = date.change(:offset => "-0400")  # adjust timezone
        date += 365 if (date.past?)             # if ruby parsed the day as in the past, add a year 
        return date
    end


end