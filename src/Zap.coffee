# Zapier doesn't like our objects wrapped so we build it up globally instead
Zap = {}

Zap.lookup_contact = (bundle, search_string) ->

Zap.custom_field_definitions = {}
Zap.custom_field_association_id_postfix = " Id"
Zap.transform_custom_fields = (bundle, object, parent_type) ->
  # Load our custom fields if not loaded yet
  Zap.custom_field_definitions[parent_type] ?= Zap.make_get_request(bundle,"https://app.goclio.com/api/v2/custom_fields?parent_type=#{parent_type}").custom_fields
  
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
        if Zap.valueExists(custom_field_value.contact)
          custom_fields[custom_field_value.custom_field.name] = custom_field_value.contact.name
        else
          custom_fields[custom_field_value.custom_field.name] = null
      if custom_field_value.hasOwnProperty("matter")
        if Zap.valueExists(custom_field_value.matter)
          custom_fields[custom_field_value.custom_field.name] = custom_field_value.matter.name
        else
          custom_fields[custom_field_value.custom_field.name] = null
      if custom_field_value.hasOwnProperty("custom_field_picklist_option")
        if Zap.valueExists(custom_field_value.custom_field_picklist_option)
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

Zap.build_request = (bundle, url, method, data) ->
  url: url
  headers:
    "Content-Type": "application/json; charset=utf-8"
    Accept: "application/json"
    Authorization: bundle.request.headers.Authorization
  method: method
  data: data
