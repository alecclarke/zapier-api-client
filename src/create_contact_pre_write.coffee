Zap.create_person_pre_write = (bundle) ->
  Zap.create_contact_pre_write(bundle, "Person")
  
Zap.create_company_pre_write = (bundle) ->
  Zap.create_contact_pre_write(bundle, "Company")

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