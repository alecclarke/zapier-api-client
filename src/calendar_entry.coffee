# Zapier hooks

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
  
  response = Zap.make_get_request(bundle, "calendars")
  users_calendar = _.filter(response.calendars, (x) -> x.type == "UserCalendar" && x.permission == "owner")
  data.calendar_id = users_calendar[0].id

  if object.matter?
    matter = Zap.find_matter(bundle, object.matter.name, object.matter.question)
    if matter?
      data.matter_id = matter.id

  bundle.request.data = JSON.stringify({"calendar_entry": data})
  bundle.request

Zap.new_calendar_entry_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  
  array = []
  for object in results.calendar_entries
    # The format of this data MUST match the sample data format in triggers "Sample Result"
    # To get a sample, build a new object with good data and create a Zap, you should see
    # bundle output (from scripting editor quicklinks) once you try and add a field in the
    # Zap editor

    data = {}
    data.id = object.id
    data.created_at = object.created_at
    data.updated_at = object.updated_at
    data.summary = object.summary
    data.description = object.description
    data.location = object.location
    data.permission = object.permission
    data.start_at = object.start_date or object.start_date_time
    data.end_at = object.end_date or object.end_date_time
    data.matter = Zap.transform_nested_attributes(object.matter)
    data.calendar = Zap.transform_nested_attributes(object.calendar)
    array.push data
  array

# Helper methods