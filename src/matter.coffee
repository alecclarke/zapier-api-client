################################################################################
#### Zapier hooks
################################################################################

Zap.create_matter_pre_write = (bundle) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.matter
  custom_field_values = request_data.custom_fields
  
  data = {}
  data.status = object.status
  data.description = object.description
  data.location = object.location;
  data.client_reference = object.client_reference;
  data.billable = object.billable;
  
  if Zap.valueExists object.client_id
    data.client_id = object.client_id
  else if object.client?
    contact = Zap.find_or_create_contact(bundle, object.client, object.client.question)
    if contact? && contact.id?
      data.client_id = contact.id

  if object.practice_area?
    practice_area = Zap.find_practice_area(bundle, object.practice_area.name, object.practice_area.question)
    if practice_area? && practice_area.id?
      data.practice_area_id = practice_area.id

  if object.responsible_attorney?
    responsible_attorney = Zap.find_user(bundle, object.responsible_attorney.name, object.responsible_attorney.question, "Attorney")
    if responsible_attorney? && responsible_attorney.id?
      data.responsible_attorney_id = responsible_attorney.id

  if object.originating_attorney?
    originating_attorney = Zap.find_user(bundle, object.originating_attorney.name, object.originating_attorney.question, "Attorney")
    if originating_attorney? && originating_attorney.id?
      data.originating_attorney_id = originating_attorney.id
  
  for own custom_field_id, custom_field_data of custom_field_values
    for own custom_field_type, custom_field_value_raw of custom_field_data
      if Zap.valueExists custom_field_value_raw
        custom_field_value = null
        data.custom_field_values ?= []
        if custom_field_type == "contact"
          cf_data = {"name": custom_field_value_raw}
          if request_data.custom_field_questions_email? && Zap.valueExists request_data.custom_field_questions_email[custom_field_id]
            cf_data["email"] = request_data.custom_field_questions_email[custom_field_id]
          question = null
          if request_data.custom_field_questions? && Zap.valueExists request_data.custom_field_questions[custom_field_id]
            question = request_data.custom_field_questions[custom_field_id]
          contact = Zap.find_or_create_contact(bundle, cf_data, question)
          if contact?
            custom_field_value = contact.id
        else if custom_field_type == "matter"
          question = null
          if request_data.custom_field_questions? && Zap.valueExists request_data.custom_field_questions[custom_field_id]
            question = request_data.custom_field_questions[custom_field_id]
          matter = Zap.find_matter(bundle, custom_field_value_raw, question)
          if matter?
            custom_field_value = matter.id
        else
          custom_field_value  = custom_field_value_raw
        
        if custom_field_value?
          data.custom_field_values.push {"custom_field_id": custom_field_id, "value": custom_field_value}
  
  bundle.request.data = JSON.stringify({"matter": data})
  bundle.request

Zap.create_person_and_matter_pre_write = (bundle) ->
  request_data = JSON.parse(bundle.request.data)
  matter = request_data.matter
  contact = request_data.contact
  custom_field_values = request_data.custom_fields
  
  # We are going to need to map our custom field types correctly, thus we need all our custom fields
  custom_field_definitions = Zap.make_get_request(bundle, "custom_fields").custom_fields
  contact_custom_field_ids = _.filter(custom_field_definitions, (x) -> x.parent_type == "Contact").map (x) -> x.id
  matter_custom_field_ids = _.filter(custom_field_definitions, (x) -> x.parent_type == "Matter").map (x) -> x.id
  
  # build our person custom field bundle data
  contact_custom_field_values = {}
  for custom_field_id in contact_custom_field_ids
    if custom_field_values[custom_field_id]?
      contact_custom_field_values[custom_field_id] = custom_field_values[custom_field_id]
  
  # build our matter custom field bundle data
  matter_custom_field_values = {}
  for custom_field_id in matter_custom_field_ids
    if custom_field_values[custom_field_id]?
      matter_custom_field_values[custom_field_id] = custom_field_values[custom_field_id]
  
  # Use our existing code to build contact request
  request_data.contact = contact
  request_data.custom_fields = contact_custom_field_values
  bundle.request.data = JSON.stringify(request_data)
  contact_request = Zap.create_person_pre_write(bundle)
  # Run our contact request ourselves
  contact_response = Zap.make_post_request(bundle, "contacts", contact_request.data)

  # Set our client id
  matter.client_id = contact_response.contact.id
  bundle.request.data = JSON.stringify({"matter": matter, "custom_fields": matter_custom_field_values})
  return Zap.create_matter_pre_write(bundle)

Zap.new_matter_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)

  # We need more info about the client, load it up
  client_ids = results.matters.map (x) ->
    if x.client?
      x.client.id
  client_ids = _.uniq(client_ids)
  client_ids = _.filter(client_ids, (x) -> Zap.valueExists x)
  clients = Zap.make_get_request(bundle, "contacts?ids=#{client_ids.toString()}").contacts

  array = []
  for object in results.matters
    # The format of this data MUST match the sample data format in triggers "Sample Result"
    # To get a sample, build a new object with good data and create a Zap, you should see
    # bundle output (from scripting editor quicklinks) once you try and add a field in the
    # Zap editor
    data = {}
    data.id = object.id
    data.created_at = object.created_at
    data.updated_at = object.updated_at
    data.display_number = object.display_number
    data.status = object.status
    data.description = object.description
    data.client_reference = object.client_reference
    data.location = object.location
    data.pending_date = object.pending_date
    data.open_date = object.open_date
    data.close_date = object.close_date
    data.billable = object.billable
    data.maildrop_address = object.maildrop_address
    data.billing_method = object.billing_method
    client = _.filter(clients, (x) -> object.client? && x.id == object.client.id)[0]
    if client?
      data.client = Zap.transform_nested_attributes(object.client)
      data.client.type = client.type
      data.client.first_name = client.first_name
      data.client.last_name = client.last_name
    data.responsible_attorney = Zap.transform_nested_attributes(object.responsible_attorney)
    data.originating_attorney = Zap.transform_nested_attributes(object.originating_attorney)
    data.practice_area = Zap.transform_nested_attributes(object.practice_area)
    data.custom_fields = Zap.transform_custom_fields(bundle, object, "Matter")
    array.push data
  array

Zap.create_matter_post_custom_action_fields = (bundle) ->
  Zap.transform_custom_action_fields(bundle, false)

Zap.create_person_and_matter_post_custom_action_fields = (bundle) ->
  Zap.transform_custom_action_fields(bundle, true)

################################################################################
#### Helper methods
################################################################################

Zap.find_matter = (bundle, query, not_found) ->
  # first check if there is a matter #show for this query, ie it is a matter id
  matter = null
  if isFinite(query)
    response = Zap.make_get_request(bundle, "matters/#{query}")
    if response.matter?
      matter = response.matter
  unless matter?
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "matters?display_number=#{encodeURIComponent(query)}&limit=2")
    if response.matters.length > 0
      matter = response.matters[0]
  
  unless matter
    switch not_found
      when "cancel"
        throw new StopRequestException("Could not find matter.")
      when "ignore"
        null #noop
      else
        throw new HaltedException('Could not find matter');
    
  matter
