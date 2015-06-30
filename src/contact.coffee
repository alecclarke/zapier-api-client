# Zapier hooks

Zap.create_person_pre_write = (bundle) ->
  Zap.create_contact_pre_write(bundle, "Person")
  
Zap.create_company_pre_write = (bundle) ->
  Zap.create_contact_pre_write(bundle, "Company")

Zap.new_contact_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  
  array = []
  for object in results.contacts
    # The format of this data MUST match the sample data format in triggers "Sample Result"
    # To get a sample, build a new object with good data and create a Zap, you should see
    # bundle output (from scripting editor quicklinks) once you try and add a field in the
    # Zap editor
    
    data = {}
    data.id = object.id
    data.created_at = object.created_at
    data.updated_at = object.updated_at
    data.name = object.name
    data.first_name = object.first_name
    data.last_name = object.last_name
    data.title = object.title
    data.company = Zap.transform_nested_attributes(object.company)
    data.email_address = Zap.flatten_array(object.email_addresses , ["name","address"])
    data.phone_number = Zap.flatten_array(object.phone_numbers, ["name", "number"])
    data.instant_messenger = Zap.flatten_array(object.instant_messengers, ["name", "address"])
    data.web_site = Zap.flatten_array(object.web_sites, ["name", "address"])
    data.address = Zap.flatten_array(object.addresses, ["name", "street", "city", "province", "postal_code", "country"])
    data.custom_field = Zap.transform_custom_fields(bundle, object, "Contact")
    array.push data
  array

# Helper methods

Zap.create_contact_pre_write = (bundle, contact_type) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.contact
  custom_field_values = request_data.custom_fields
  
  data = {}
  data.type = contact_type
  if Zap.valueExists object.first_name and Zap.valueExists object.last_name
    data.first_name = object.first_name
    data.last_name = object.last_name
  else
    data.name = object.name

  if Zap.valueExists object.company_id
    data.company_id = object.company_id
  else if contact_type == "Person" && object.company?
    company = Zap.find_or_create_contact(bundle, object.company, object.company.question, "Company")
    if company? && company.id?
      data.company_id = company.id
  
  if object.phone_number? && object.phone_number.number?
    phone_type = object.phone_number.name
    phone_type ?= "Work"
    data.phone_numbers = [{"name": phone_type, "number": object.phone_number.number}]
  
  if object.email_address? && object.email_address.address?
    email_address_type = object.email_address.name
    email_address_type ?= "Work"
    data.email_addresses = [{"name": email_address_type, "address": object.email_address.address}]

  if object.address? && object.address.street? && object.address.city?
    address_type = object.address.name
    address_type ?= "Work"
    data.addresses = [{
      "name": address_type,
      "street": object.address.street,
      "city": object.address.city,
      "province": object.address.province,
      "postal_code": object.address.postal_code,
      "country": object.address.country
    }]

  
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
  
  bundle.request.data = JSON.stringify({"contact": data})
  bundle.request

Zap.find_or_create_contact = (bundle, object, not_found, search_contact_type) ->
  contact = Zap.find_contact(bundle, object, search_contact_type)
  unless contact
    switch not_found
      when "Person", "Company"
        contact = Zap.create_contact(bundle, object, not_found)
      when "cancel"
        throw new StopRequestException("Could not find contact.")
      when "ignore"
        null #noop
      else
        throw new HaltedException('Could not find contact');
      
  contact
  
Zap.find_user_or_contact_or_create_contact = (bundle, object, not_found) ->
  found_object = Zap.find_user_or_contact(bundle, object)

  unless found_object
    switch not_found
      when "Person", "Company"
        found_object= Zap.create_contact(bundle, object, not_found)
      when "cancel"
        throw new StopRequestException("Could not find contact or user.")
      when "ignore"
        null #noop
      else
        throw new HaltedException('Could not find contact or user.');  
  
  found_object

Zap.find_user_or_contact = (bundle, object) ->
  found_object = null
  if isFinite(bundle.name)
    found_object ?= Zap.find_user_by_id(bundle, bundle.name)
    found_object ?= Zap.find_contact_by_id(bundle, bundle.name)
    
  else if Zap.valueExists object.email
    found_object ?= Zap.find_user_by_query(bundle, object.email)
    found_object ?= Zap.find_contact_by_email(bundle, object.email)
    
  else if Zap.valueExists object.name
    found_object ?= Zap.find_user_by_query(bundle, object.name)
    found_object ?= Zap.find_contact_by_name(bundle, object.name)
  
  found_object

Zap.find_contact = (bundle, object, search_contact_type) ->
  contact = null
  # if name is a number, try by id
  if isFinite(object.name)
    contact ?= Zap.find_contact_by_id(bundle, object.name, search_contact_type)
  # if email set, try to find by it
  else if Zap.valueExists object.email 
    contact ?= Zap.find_contact_by_email(bundle, object.email, search_contact_type)
  # If no email or not found, try with the name
  else if Zap.valueExists object.name
    contact ?= Zap.find_contact_by_name(bundle, object.name, search_contact_type)
  contact

Zap.find_contact_by_id = (bundle, id, search_contact_type) ->
  contact = null
  if isFinite(id)
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "contacts?ids=#{encodeURIComponent(id)}&limit=2#{Zap.find_contact_type_to_query(search_contact_type)}")
    if response.contacts.length > 0
      contact = response.contacts[0]
  contact

Zap.find_contact_by_email = (bundle, email, search_contact_type) ->
  contact = null
  # Sanity check on email
  if Zap.valueExists email
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "contacts?query=#{encodeURIComponent(email)}&limit=2#{Zap.find_contact_type_to_query(search_contact_type)}")
    if response.contacts.length > 0
      contact = response.contacts[0]
  contact

Zap.find_contact_by_name = (bundle, name, search_contact_type) ->
  contact = null
  if Zap.valueExists name
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "contacts?name=#{encodeURIComponent(name)}&limit=2#{Zap.find_contact_type_to_query(search_contact_type)}")
    if response.contacts.length > 0
      contact = response.contacts[0]
  contact

Zap.create_contact = (bundle, object, contact_type) ->
  if Zap.valueMissing object.name
    throw new HaltedException("Could not create #{contact_type} without a name")
  data = { "type": contact_type, "name": object.name }
  # if email set, add it
  if Zap.valueExists object.email
    data["email_addresses"] = [{"name": "Work", "address": object.email}]
  response = Zap.make_post_request(bundle, "contacts", JSON.stringify({"contact": data}))
  unless response.hasOwnProperty("contact")
    throw new HaltedException('Could not create new contact');
  response.contact
  
Zap.find_contact_type_to_query = (search_contact_type) ->
  if Zap.valueExists search_contact_type
    search_contact_type= "&type=#{encodeURIComponent(search_contact_type)}"
  else
    search_contact_type= ""
  search_contact_type