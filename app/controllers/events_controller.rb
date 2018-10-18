class EventsController < ApplicationController

	def index
		@event = Event.new
		@events = Event.all

		@day_times = File.read('./day_times_config.json')
		@day_times = JSON.parse(@day_times)

	end

	def create
		Event.create!({
			:name => params[:event][:name],
			:weekly_occurrence => params[:event][:weekly_occurrence],
			:duration => params[:event][:duration]
		})

		redirect_to events_url
	end

	def delete
		p params[:event_id]
		Event.where(id: params[:event_id]).destroy_all

		redirect_to events_url
	end

end
