Zap.create_calendar_entry_pre_write = (bundle) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.calendar_entry
  
  data = {}
  data.summary = object.summary
  data.description = object.description
  data.location = object.location
  
  if object.all_day
    data.start_date = object.start_at
    data.end_date = object.end_at
  else
    data.start_date_time = object.start_at
    data.end_date_time = object.end_at
  
  response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/calendars")
  users_calendar = _.filter(response.calendars, (x) -> x.type == "UserCalendar" && x.permission == "owner")
  data.calendar_id = users_calendar[0].id

  if object.matter?
    matter = Zap.find_matter(bundle, object.matter.name, object.matter.question)
    if matter?
      data.matter_id = matter.id

  bundle.request.data = JSON.stringify({"calendar_entry": data})
  bundle.request