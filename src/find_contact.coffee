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
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/contacts?ids=#{encodeURIComponent(id)}&limit=2#{Zap.find_contact_type_to_query(search_contact_type)}")
    if response.contacts.length > 0
      contact = response.contacts[0]
  contact

Zap.find_contact_by_email = (bundle, email, search_contact_type) ->
  contact = null
  # Sanity check on email
  if Zap.valueExists email
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/contacts?query=#{encodeURIComponent(email)}&limit=2#{Zap.find_contact_type_to_query(search_contact_type)}")
    if response.contacts.length > 0
      contact = response.contacts[0]
  contact

Zap.find_contact_by_name = (bundle, name, search_contact_type) ->
  contact = null
  if Zap.valueExists name
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/contacts?name=#{encodeURIComponent(name)}&limit=2#{Zap.find_contact_type_to_query(search_contact_type)}")
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
  response = Zap.make_post_request(bundle, "https://app.goclio.com/api/v2/contacts", JSON.stringify({"contact": data}))
  unless response.hasOwnProperty("contact")
    throw new HaltedException('Could not create new contact');
  response.contact
  
Zap.find_contact_type_to_query = (search_contact_type) ->
  if Zap.valueExists search_contact_type
    search_contact_type= "&type=#{encodeURIComponent(search_contact_type)}"
  else
    search_contact_type= ""
  search_contact_type