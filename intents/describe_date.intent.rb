=begin

"Alexa ask Calendar Assistant what's happening on {date}"

=end

require './intents/libs/Utils.rb'

intent "CA_DescribeDateIntent" do

    client_options = Utils::get_client_options()

    # convert date string to DateTime object 
    date = Utils::string_to_dateTime(request.slot_value("date"))

    # setup google outh2 authentication & connect to calendar
    service = Utils::connect_google_calendar()
    p client
    p client.code

    # set start and end times to strings one day apart
    start_time = (date).iso8601
    end_time = (date + 1).iso8601

    # query for calendar events
    event_list = service.list_events(
        'primary',
        single_events: true,
        order_by: 'starttime',
        time_min: start_time,
        time_max: end_time
    )

    # map events to more alexa speech friendly objects
    events = []
    event_list = event_list.items
    event_list.each do |item|
        event_start_time = (item.start.date_time.hour.to_i < 12) ? " AM" : " PM"
        event_start_time = (item.start.date_time.minute.to_i > 0) ? " " + item.start.date_time.minute.to_s + event_start_time : event_start_time
        event_start_time = (item.start.date_time.hour.to_i % 12).to_s + event_start_time

        events.push({
            :summary => item.summary,
            :start_time => event_start_time
        })
    end

    # create strings that alexa says
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
        res.push(event[:start_time])
        res.push(". ")
    end

    # return response to alexa
    return Utils::build_alexa_response((events.length > 0) ? res.join : "You don't have any events scheduled on #{date_speach}")

# if the authorization is expired use refresh token to get new access code
rescue Google::Apis::AuthorizationError
        
        # tokens['response'] = client.refresh!
        
        # File.open('./google_tokens.json', 'w') do |f|
        #     f.write(tokens.to_json);
        # end

        Utils::refresh_google_client()

        retry

end