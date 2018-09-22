intent "CA_NewEventIntent" do

    client_options = {
        client_id: Rails.application.secrets.google_client_id,
        client_secret: Rails.application.secrets.google_client_secret,
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
        redirect_uri: 'http://localhost:3000/api/callback'
    }

    # get slots
    event_name = request.slot_value('event_name')
    day_of_week = request.slot_value('day')
    start_time = request.slot_value('start_time')
    end_time = request.slot_value('end_time')

    # set date
    today = DateTime.now.beginning_of_day
    respond("I'm sorry, please tell me which day of the week you want me to describe") unless (Date::DAYNAMES.index(day_of_week))

    # find day of the weeks according date 
    num_days_over = Date::DAYNAMES.index(day_of_week) - today.wday
    num_days_over += 7 if (num_days_over <= 0) 
    date = today + num_days_over

    start_date = date.change({ hour: start_time[0,2].to_i, min: start_time[3,4].to_i  })
    end_date = date.change({ hour: end_time[0,2].to_i, min: end_time[3,4].to_i })

    # adjust for am/pm
    end_date += Rational(12,24) if (start_date > end_date)

    # connect to google API
    client = Signet::OAuth2::Client.new(client_options)
    google_tokens = File.read('./google_tokens.json')
    tokens = JSON.parse(google_tokens)
    client.update!(tokens['response'])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    event = Google::Apis::CalendarV3::Event.new({
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_date),
        end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_date),
        summary: event_name
    })

    service.insert_event('primary', event)

    date_speech = [
        "#{day_of_week} ",
        "#{Date::MONTHNAMES[date.month]} ",
        "#{date.day} ",
        "#{date.year}"
    ].join

    res = [
        "I've added the event, ",
        "#{event_name}, on ",
        date_speech
    ].join

    return {
        "version": "1.0",
        "response": {
            "outputSpeech": {
                "type": "PlainText",
                "text": res
            },
            "shouldEndSession": true
        }
    }

rescue Google::Apis::AuthorizationError
    client.code = tokens['code']
    tokens['response'] = client.refresh!
    
    File.open('./google_tokens.json', 'w') do |f|
        f.write(tokens.to_json);
    end

    retry

end