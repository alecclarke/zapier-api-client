# Zapier doesn't like our objects wrapped so we build it up globally instead
Zap = {}

################################################################################
#### Request methods
################################################################################

Zap.build_api_url = (domain, resource_string) ->
  # because we added domain to the auth fields later, a domain might not always get passed in
  # in that case default to the standard Clio URL, because that's all we had then
  domain = "https://app.goclio.com" if not domain
  return domain + "/api/v2/" + resource_string

Zap.build_request = (bundle, url, method, data) ->
  url: url
  headers:
    "Content-Type": "application/json; charset=utf-8"
    Accept: "application/json"
    Authorization: bundle.request.headers.Authorization
  method: method
  data: data

Zap.make_get_request =  (bundle, resource_url) ->
  url = Zap.build_api_url(bundle.auth_fields.domain, resource_url)
  JSON.parse z.request(Zap.build_request(bundle, url, "GET", null)).content

Zap.make_post_request = (bundle, resource_url, data) ->
  url = Zap.build_api_url(bundle.auth_fields.domain, resource_url)
  JSON.parse z.request(Zap.build_request(bundle, url, "POST", data)).content

################################################################################
#### Helper methods
################################################################################

Zap.value_exists = (value) ->
  value not in ["", null, undefined]

Zap.value_missing = (value) ->
  value in ["", null, undefined]

Zap.flatten_array = (array, default_keys) ->
  # Find our defaults
  if array.length > 0
    data = _.filter(array, (x) -> (x.hasOwnProperty("default_email") and x.default_email == true) or (x.hasOwnProperty("default_number") and x.default_number == true))[0]
  # If none found, user first item
  data ?= array[0]
  # If array empty use empty hash
  data ?= {} # missing case
  
  return_data = {}
  for key in default_keys
    return_data[key] = data[key]
    return_data[key] ?= null
  
  return_data 

################################################################################
#### Transformation methods
################################################################################

Zap.custom_field_definitions = {}
Zap.custom_field_association_id_postfix = " Id"

Zap.transform_custom_fields = (bundle, object, parent_type) ->
  # Load our custom fields if not loaded yet
  Zap.custom_field_definitions[parent_type] ?= Zap.make_get_request(bundle,"custom_fields?parent_type=#{parent_type}").custom_fields
  
  # Set our defaults for all custom fields
  custom_fields = {}
  for custom_field_definition in Zap.custom_field_definitions[parent_type]
    custom_fields[custom_field_definition.name] = null
    if custom_field_definition.field_type in ["picklist", "matter", "contact"]
      custom_fields["#{custom_field_definition.name}#{Zap.custom_field_association_id_postfix}"] = null
  
  # Set our custom field values from the object
  for custom_field_value in object.custom_field_values
    # for assocation custom fields, our value works differently
    if custom_fields.hasOwnProperty("#{custom_field_value.custom_field.name}#{Zap.custom_field_association_id_postfix}")
      # our value is the association id
      custom_fields["#{custom_field_value.custom_field.name}#{Zap.custom_field_association_id_postfix}"] = custom_field_value.value
      # We want the name in the regular field
      if custom_field_value.hasOwnProperty("contact")
        if Zap.value_exists(custom_field_value.contact)
          custom_fields[custom_field_value.custom_field.name] = custom_field_value.contact.name
        else
          custom_fields[custom_field_value.custom_field.name] = null
      if custom_field_value.hasOwnProperty("matter")
        if Zap.value_exists(custom_field_value.matter)
          custom_fields[custom_field_value.custom_field.name] = custom_field_value.matter.name
        else
          custom_fields[custom_field_value.custom_field.name] = null
      if custom_field_value.hasOwnProperty("custom_field_picklist_option")
        if Zap.value_exists(custom_field_value.custom_field_picklist_option)
          custom_fields[custom_field_value.custom_field.name] = custom_field_value.custom_field_picklist_option.name
        else
          custom_fields[custom_field_value.custom_field.name] = null
    else
      custom_fields[custom_field_value.custom_field.name] = custom_field_value.value
  custom_fields

Zap.transform_nested_attributes = (object) ->
  object ?= {"id":null, "name":null}
  data = {"id": object.id, "name": object.name}
  if object.hasOwnProperty("type")
    data["type"] = object.type
  if object.hasOwnProperty("email")
    data["email"] = object.email
  data

Zap.custom_field_question = (object,choices) ->
  # Ask if how they want to handle missing matters
  question = {}
  question.required = true
  question.key = "custom_field_questions__#{object.id}"
  question.label = "#{object.name} (#{object.field_type}) not found?"
  question.help_text = "What happens when we can't find #{object.field_type}?"
  question.type = "unicode"
  question.default = "ignore"
  question.choices = choices
  question

Zap.transform_custom_action_fields = (bundle, include_parent_type) ->
  results = JSON.parse(bundle.response.content)
  
  array = []
  for object in results.custom_fields
    if object.field_type not in ["time"]
      data = {}
      data.required = false # don't use object.displayed, we will add required custom fields when they are ready
      # Encode our field type into our data key
      # We will use this later to check if it is a matter or contact
      # custom field type, if so search for the matter or contact
      data.key = "custom_fields__#{object.id}__#{object.field_type}"
      data.label = object.name
      if include_parent_type
        data.label = "#{object.parent_type} #{data.label}"
        
      data.help_text = "Enter a/an #{object.field_type} value"
      
      data.type = switch object.field_type
        when "text_line", "url", "email" then "unicode"
        when "text_area" then "text"
        when "numeric", "currency" then "decimal"
        when "checkbox" then "bool"
        when "date" then "datetime"
        when "picklist" then "int"
        when "matter", "contact" then "unicode"
      
      if object.field_type == "picklist"
        choices = {"none": ""}
        for option in object.custom_field_picklist_options
          unless !!option.deleted_at
            choices[option.id] = option.name
        data.choices = choices
      
      array.push data
      
      # Ask what to do if 
      if object.field_type == "matter"
        array.push Zap.custom_field_question(object,"cancel|Stop Zap,ignore|Leave empty")
      if object.field_type == "contact"
        question = {}
        question.required = false
        question.key = "custom_field_questions_email__#{object.id}"
        question.label = "#{data.label} email"
        question.help_text = "Contact email referenced in #{object.name}. If set we will only search on email. If no contact is found, and option to create is set, we will also set the new contact's email."
        question.type = "unicode"
        array.push question
        array.push Zap.custom_field_question(object,"cancel|Stop Zap,ignore|Leave empty,Person|Create new person,Company|Create new company")
        
  array
