module Unfuzzle

  class TimeEntry

    include Graft
    
    attr_accessor :project_id
    
    attribute :date
    attribute :description
    attribute :hours
    attribute :person_id, :from => "person-id", :type => :integer
    attribute :ticket_id, :from => "ticket-id", :time => :integer
    attribute :project_id

    # Hash representation of this time entry's data (for updating)
    def to_hash
      {
        'date'           => date,
        'description'    => description,
        'hours'          => hours,
        'person-id'      => person_id,
        "ticket-id"      => ticket_id
      }
    end


    # times for project
    def self.time_invested(project_id, start_date, end_date)
      response = Request.get("/projects/#{project_id}/time_invested", query(start_date, end_date))
      collection_from(response.body, 'time-entries/time-entry')
    end

    # times for account
    def self.all_time_invested(start_date, end_date)
      response = Request.get("/account/time_invested", query(start_date, end_date))
      collection_from(response.body, 'time-entries/time-entry')
    end

    def self.all_for_ticket(ticket, start_date = nil, end_date = nil)
      response = Request.get("/projects/#{ticket.project_id}/tickets/#{ticket.id}/time_entries", query(start_date, end_date))
      collection_from(response.body, 'time-entries/time-entry')
    end

    # Create a ticket in unfuddle
    def create(project_id, ticket_id)
      resource_path = "/projects/#{project_id}/tickets/#{ticket_id}/time_entries"
      Request.post(resource_path, self.to_xml('time-entry'))
    end

  protected

    def self.query(start_date, end_date)
      # [person, ticket, priority, component, version, severity, milestone, due_on, reporter, assignee, status, resolution]
      group = "ticket"
      query = "?group_by=#{group}"
      query += "&start_date=#{start_date.strftime("%Y/%m/%d")}" if start_date
      query += "&end_date=#{end_date.strftime("%Y/%m/%d")}" if end_date
      query
    end

    # Return a list of all tickets for all account user registred at
    def self.time_invested_for_account(start_date, end_date)
      group = "project"
      query = "?group_by=#{group}&start_date=#{start_date.strftime("%Y/%m/%d")}&end_date=#{end_date.strftime("%Y/%m/%d")}"
      response = Request.get("/account/time_invested", query)
      groups =  Unfuzzle::Group.collection_from(response.body, 'group')
      coll = []

      groups.each do |group|
        tcoll = collection_from(group.source_data, 'time-entries/time-entry')
        tcoll.each do |te|
          te.project_id = group.title
        end
        coll << tcoll
      end

      coll.flatten
    end
  end
end
  
  