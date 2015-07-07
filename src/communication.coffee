################################################################################
#### Zapier hooks
################################################################################

Zap.create_communication_pre_write = (bundle) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.communication
  
  data = {}
  data.type = "EmailCommunication"
  data.subject = object.subject
  data.body = object.body
  data.date = object.date
  
  if object.sender?
    sender = Zap.find_user_or_contact_or_create_contact(bundle, object.sender, object.sender.question)
    if sender? && sender.id?
      sender_type = "User"
      if sender.type? && sender.type in ["Person", "Company"]
        sender_type = "Contact"
      data.senders = [{"id": sender.id, "type": sender_type}]

  if object.receiver?
    receiver = Zap.find_user_or_contact_or_create_contact(bundle, object.receiver, object.receiver.question)
    if receiver? && receiver.id?
      receiver_type = "User"
      if receiver.type? && receiver.type in ["Person", "Company"]
        receiver_type = "Contact"
      data.receivers = [{"id": receiver.id, "type": receiver_type}]

  if object.matter?
    matter = Zap.find_matter(bundle, object.matter.name, object.matter.question)
    if matter?
      data.matter_id = matter.id

  bundle.request.data = JSON.stringify({"communication": data})
  bundle.request

Zap.new_communication_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  
  array = []
  for object in results.communications
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
    data.subject = object.subject
    data.body = object.body
    data.matter = Zap.transform_nested_attributes(object.matter)
    data.sender = Zap.flatten_array(object.senders, ["id","name", "type"])
    data.receiver = Zap.flatten_array(object.receivers, ["id","name", "type"])
    array.push data
  array

################################################################################
#### Helper methods
################################################################################
