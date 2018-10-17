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
        render :json => Ralyxa::Skill.handle(request)
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
