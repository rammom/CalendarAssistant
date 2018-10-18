=begin

"Alexa ask Calendar Assistant to build next week"

=end

require './intents/libs/Utils.rb'
require 'json'

intent "CA_BuildWeek" do

    # setup google outh2 authentication & connect to calendar
    service = Utils::connect_google_calendar()

    # find first day of next week (sunday)
    date = DateTime.parse("Sunday")
    date += date > DateTime.now ? 0 : 7

    # Make strings of first and last days of week
    start_time = date.iso8601
    end_time = (date + 7).iso8601


    # query for calendar events
    event_list = service.list_events(
        'primary',
        single_events: true,
        order_by: 'starttime',
        time_min: start_time,
        time_max: end_time
    ).items

    # get day times from file
    day_times = File.read('./day_times_config.json')
    day_times = JSON.parse(day_times)

    # get all weekly events
    @weekly_events = Event.all

    # copy over to classic array
    weekly_events = []
    @weekly_events.each do |event|
        weekly_events.push({
            :id => event.id,
            :name => event.name,
            :weekly_occurrence => event.weekly_occurrence,
            :duration => event.duration,
            :days_added => []
        })
    end

    # sort events by descending duration
    weekly_events.sort_by { |event| -event[:duration] }

    p weekly_events

    week_days = Array.new(7)
    7.times do |day|
        week_days[day] = {
            :events => [],
            :busy_time => (24 - (day_times["end"].to_i - day_times["start"].to_i)) * 60,
            :date => (date + day)
        }
    end

    event_list.each do |event|

        # find free time per day
        # find event's day of week
        start_time = DateTime.parse(event.start.date_time.iso8601)
        end_time = DateTime.parse(event.end.date_time.iso8601)
        duration = (end_time - start_time).to_f * 24 * 60
        day_index = start_time.wday

        week_days[day_index][:events].push({
            :start_time => start_time,
            :end_time => end_time,
            :duration => duration
        })

        week_days[day_index][:busy_time] += duration

    end

    day_queue = PQueue.new(week_days){ |a, b| a[:busy_time] < b[:busy_time] }

    while day_queue.size > 0 do
        day = day_queue.pop

        start_point = day[:date]
        start_point += Rational(day_times["start"], 24)
        start_point = start_point.change(:offset => "-0400")  # adjust timezone

        end_point = day[:date]
        end_point += Rational(day_times["end"], 24)
        end_point = end_point.change(:offset => "-0400")  # adjust timezone        

        next_point = end_point

        # for all events on day within time range
        for i in 0..day[:events].length do

            # if there is an event on this day (ruby enters the above loop event when day[:events].length == 0)
            if day[:events].length - i > 0


                event = day[:events][i]

                # if last element (out of range)
                next if event == nil

                next if event[:end_time] <= start_point || event[:start_time] >= end_point

                # squeeze in range
                start_point = event[:end_time] if event[:start_time] <= start_point

                next_point = event[:start_time]

                if next_point <= start_point
                    if day[:events][i+1] != nil 
                        evt = day[:events][i+1]
                        next_point = evt[:start_time]
                    else
                        next_point = end_point
                    end
                end

            else
                next_point = end_point
            end

            free_space = (next_point - start_point).to_f * 24 * 60


            p weekly_events
            for j in 0..weekly_events.length-1 do
                # next if weekly_events[j] == nil
                next if weekly_events[j][:weekly_occurrence] == 0
                p j
                weekly_events[j][:days_added] = [] if weekly_events[j][:days_added].length == 7
                next if weekly_events[j][:days_added].include? day[:date].wday
                if weekly_events[j][:duration] < free_space
                    # schedule event
                    # build new event object
                    new_event = Google::Apis::CalendarV3::Event.new({
                        start: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_point),
                        end: Google::Apis::CalendarV3::EventDateTime.new(date_time: start_point + Rational(weekly_events[j][:duration], 24*60)),
                        summary: weekly_events[j][:name]
                    })

                    # set event on the primary calendar
                    p "inserting event"
                    p weekly_events[j]
                    service.insert_event('primary', new_event)

                    # insert into day's events
                    day[:events].insert(i+1, {
                        :start_time => start_point,
                        :end_time => start_point + Rational(weekly_events[j][:duration], 24*60),
                        :duration => weekly_events[j][:duration]
                    })

                    # add day to event
                    weekly_events[j][:days_added].push(day[:date].wday)

                    start_point += Rational(weekly_events[j][:duration], 24*60)

                    # -1 from event occurrence
                    weekly_events[j][:weekly_occurrence] -= 1

                    #break
                end
            end

            if day[:events].length == 0 || event == nil
                break
            end

            start_point = event[:end_time]


        end

    end

    return Utils::build_alexa_response("It is built.")

# if the authorization is expired use refresh token to get new access code
rescue Google::Apis::AuthorizationError
        
        # tokens['response'] = client.refresh!
        
        # File.open('./google_tokens.json', 'w') do |f|
        #     f.write(tokens.to_json);
        # end

        Utils::refresh_google_client()

        retry

end