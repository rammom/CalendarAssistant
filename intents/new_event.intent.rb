=begin

    "Alexa ask calendar assistant to schedule {event_name} on {day_of_week} from {start_time} to {end_time}"
    "Alexa ask calendar assistant to schedule {event_name} this {day_of_week} from {start_time} to {end_time}"
=end

require './intents/libs/Utils.rb'

intent "CA_NewEventIntent" do

    client_options = Utils::get_client_options()

    # get slots
    event_name = request.slot_value('event_name')
    day_of_week = request.slot_value('day')
    start_time = request.slot_value('start_time')
    end_time = request.slot_value('end_time')

    # set date
    today = DateTime.now.beginning_of_day
    
    # check if date given is a day of the week
    unless (Date::DAYNAMES.index(day_of_week))
        return build_alexa_response("I'm sorry, next time please tell me which day of the week you want me to add an event," \
                             "  For example." \
                             "  'Alexa ask calendar assistant to schedule this on day of the week from start time to end time'")
    end

    # find day of the weeks according date, add buffer to days of week that have already passed
    num_days_over = Date::DAYNAMES.index(day_of_week) - today.wday
    num_days_over += 7 if (num_days_over <= 0) 

    # compute date
    date = today + num_days_over

    # set exact start and end time on the date
    start_date = date.change({ hour: start_time[0,2].to_i, min: start_time[3,4].to_i  })
    end_date = date.change({ hour: end_time[0,2].to_i, min: end_time[3,4].to_i })

    # adjust for am/pm, make sure start time is before end time
    end_date += Rational(12,24) if (start_date > end_date)

    # connect to google API
    service = Utils::connect_google_calendar()

    # build new event object
    event = Google::Apis::CalendarV3::Event.new({
        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_date),
        end: Google::Apis::CalendarV3::EventDateTime.new(date_time: end_date),
        summary: event_name
    })

    # set event on the primary calendar
    service.insert_event('primary', event)

    # setup alexa response text
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

    return Utils::build_alexa_response(res)

rescue Google::Apis::AuthorizationError
    # client.code = tokens['code']
    # tokens['response'] = client.refresh!
    
    # File.open('./google_tokens.json', 'w') do |f|
    #     f.write(tokens.to_json);
    # end

    Utils::refresh_google_client(client)

    retry

end