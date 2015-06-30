# Zapier hooks

Zap.create_time_entry_pre_write = (bundle) ->
  Zap.create_activity_pre_write(bundle, "TimeEntry")

Zap.create_expense_entry_pre_write = (bundle) ->
  Zap.create_activity_pre_write(bundle, "ExpenseEntry")

Zap.new_activity_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  
  array = []
  for object in results.activities
    # The format of this data MUST match the sample data format in triggers "Sample Result"
    # To get a sample, build a new object with good data and create a Zap, you should see
    # bundle output (from scripting editor quicklinks) once you try and add a field in the
    # Zap editor

    data = {}
    data.id = object.id
    data.created_at = object.created_at
    data.updated_at = object.updated_at
    data.type = object.type
    data.date = object.date
    data.quantity = object.quantity
    data.price = object.price
    data.total = object.total
    data.note = object.note
    data.billed = object.billed
    data.activity_description = Zap.transform_nested_attributes(object.activity_description)
    data.user = Zap.transform_nested_attributes(object.user)
    data.matter = Zap.transform_nested_attributes(object.matter)
    data.bill = Zap.transform_nested_attributes(object.bill)
    array.push data
  array

# Helper methods

Zap.create_activity_pre_write = (bundle, activity_type) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.activity
  
  data = {}
  data.type = activity_type
  data.date = object.date
  data.note = object.note
  if activity_type == "TimeEntry"
    data.price = object.price
    data.quantity = object.quantity * 60*60 # input in hours, but we take seconds
  else
    # we don't support expense units, so lets fake it
    data.price = object.price * object.quantity
    data.quantity = 1
  
  if object.user?
    user = Zap.find_user(bundle, object.user.name, object.user.question)
    if user?
      data.user_id = user.id
  
  if object.matter?
    matter = Zap.find_matter(bundle, object.matter.name, object.matter.question)
    if matter?
      data.matter_id = matter.id
  
  bundle.request.data = JSON.stringify({"activity": data})
  bundle.request   