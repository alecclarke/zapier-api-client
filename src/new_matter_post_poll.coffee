Zap.new_matter_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)

  # We need more info about the client, load it up
  client_ids = results.matters.map (x) ->
    if x.client?
      x.client.id
  client_ids = _.uniq(client_ids)
  client_ids = _.filter(client_ids, (x) -> Zap.valueExists x)
  clients = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/contacts?ids=#{client_ids.toString()}").contacts

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