=begin
 
    "Alexa ask Calendar Assistant to describe {day of week}"
    
=end

require './intents/libs/Utils.rb'

intent "CA_DescribeIntent" do

    client_options = Utils::get_client_options()

    # set dates
    day_of_week = request.slot_value("day")

    today = DateTime.now.beginning_of_day

    # check if date given is a day of the week
    unless (Date::DAYNAMES.index(day_of_week))
        return build_alexa_response("I'm sorry, next time please tell me which day of the week you want me to describe," \
                             "  if you want to know what's happening on a specific date, say." \
                             "  'Alexa ask calendar assistant what\'s happening on date'")
    end

    # add buffer to days of week that have already passed
    num_days_over = Date::DAYNAMES.index(day_of_week) - today.wday
    num_days_over += 7 if (num_days_over <= 0) 

    # compute date to query
    describe_date = today + num_days_over

    # setup google outh2 authentication & connect to calendar
    service = Utils::connect_google_calendar()

    # set start and end times to strings one day apart
    start_time = describe_date.iso8601
    end_time = (describe_date + 1).iso8601

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
        start_time = (item.start.date_time.hour.to_i < 12) ? " AM" : " PM"
        start_time = (item.start.date_time.minute.to_i > 0) ? " " + item.start.date_time.minute.to_s + start_time : start_time
        start_time = (item.start.date_time.hour.to_i % 12).to_s + start_time

        events.push({
            :summary => item.summary,
            :start_time => start_time
        })
    end

    # create strings that alexa says
    date_speech = [
        "#{day_of_week} ",
        "#{Date::MONTHNAMES[describe_date.month]} ",
        "#{describe_date.day} ",
        "#{describe_date.year}"
    ].join

    res = [ 
        "On ",
        date_speech,
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