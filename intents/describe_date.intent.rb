intent "CA_DescribeDateIntent" do

    client_options = {
        client_id: Rails.application.secrets.google_client_id,
        client_secret: Rails.application.secrets.google_client_secret,
        authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
        token_credential_uri: 'https://accounts.google.com/o/oauth2/token',
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR,
        redirect_uri: 'http://localhost:3000/api/callback'
    }

    # parse date
    date = DateTime.parse(request.slot_value("date")).beginning_of_day
    date = date.change(:offset => "-0400")  # adjust timezone
    date += 365 if (date.past?)

    # connect to google API
    client = Signet::OAuth2::Client.new(client_options)
    google_tokens = File.read('./google_tokens.json')
    tokens = JSON.parse(google_tokens)
    client.update!(tokens['response'])

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = client

    # adjust to time zones
    startTime = (date).iso8601
    endTime = (date + 1).iso8601

    event_list = service.list_events(
        'primary',
        single_events: true,
        order_by: 'startTime',
        time_min: startTime,
        time_max: endTime
    )

    events = []
    event_list = event_list.items
    event_list.each do |item|
        startTime = (item.start.date_time.hour.to_i < 12) ? " AM" : " PM"
        startTime = (item.start.date_time.minute.to_i > 0) ? " " + item.start.date_time.minute.to_s + startTime : startTime
        startTime = (item.start.date_time.hour.to_i % 12).to_s + startTime

        events.push({
            :summary => item.summary,
            :startTime => startTime
        })
    end

    date_speach = [
        "#{Date::DAYNAMES[date.wday]} ",
        "#{Date::MONTHNAMES[date.month]} ",
        "#{date.day} ",
        "#{date.year}"
    ].join

    res = [ 
        "On ",
        date_speach,
        ", you have, "
    ]

    events.each do |event|
        res.push(event[:summary])
        res.push(" at ")
        res.push(event[:startTime])
        res.push(". ")
    end

    return {
        "version": "1.0",
        "response": {
            "outputSpeech": {
                "type": "PlainText",
                "text": (events.length > 0) ? res.join : "You don't have any events scheduled on #{date_speach}"
            },
            "shouldEndSession": true
        }
    }

rescue Google::Apis::AuthorizationError
        
        tokens['response'] = client.refresh!
        
        File.open('./google_tokens.json', 'w') do |f|
            f.write(tokens.to_json);
        end

        retry

end