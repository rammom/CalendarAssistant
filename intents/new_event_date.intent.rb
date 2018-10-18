=begin

    "Alexa ask calendar assistant to schedule {event_name} on {date} from {start_time} to {end_time}"

=end

require './intents/libs/Utils.rb'

intent "CA_NewEventDateIntent" do

    client_options = Utils::get_client_options()

    # get slots
    event_name = request.slot_value('event_name')
    start_time = request.slot_value('start_time')
    end_time = request.slot_value('end_time')

    # convert date string to DateTime object 
    date = Utils::string_to_dateTime(request.slot_value("date"))

    # set start and end time on corresponding date
    start_date = date.change({ hour: start_time[0,2].to_i, min: start_time[3,4].to_i  })
    end_date = date.change({ hour: end_time[0,2].to_i, min: end_time[3,4].to_i })

    # adjust for am/pm
    end_date += Rational(12,24) if (start_date > end_date)

    # connect to google API
    service = Utils::connect_google_calendar()

    # create a new google calendar event object
    event = Google::Apis::CalendarV3::Event.new({
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_date),
        end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_date),
        summary: event_name
    })

    # add event to primary calendar
    service.insert_event('primary', event)

    date_speech = [
        "#{Date::DAYNAMES[date.wday]} ",
        "#{Date::MONTHNAMES[date.month]} ",
        "#{date.day} ",
        "#{date.year}"
    ].join

    res = [
        "I've added the event, ",
        "#{event_name}, on ",
        date_speech
    ].join

    return Utils::build_alexa_response(res)

rescue Google::Apis::AuthorizationError
    # client.code = tokens['code']
    # tokens['response'] = client.refresh!
    
    # File.open('./google_tokens.json', 'w') do |f|
    #     f.write(tokens.to_json);
    # end

    p '\n\n\n\n\n\nrefreshing\n\n\n\n\n'

    Utils::refresh_google_client()

    retry

end