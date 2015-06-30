# Zapier hooks

Zap.create_task_pre_write = (bundle) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.task
  
  data = {}
  data.name = object.name
  data.due_at = object.due_at
  data.description = object.description
  data.priority = object.priority
  data.is_private = object.is_private
  
  if object.assignee?
    assignee = Zap.find_user(bundle, object.assignee.name, "ignore")
    if assignee?
      data.assignee_id = assignee.id
  
  if object.matter?
    matter = Zap.find_matter(bundle, object.matter.name, object.matter.question)
    if matter?
      data.matter_id = matter.id
  
  bundle.request.data = JSON.stringify({"task": data})
  bundle.request

Zap.new_task_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  Zap.process_task_response_content(results)

Zap.new_task_webhook_catch_hook = (bundle) ->
  # we use skinny webhooks, so we need to get the real content for zapier
  # webhook notifications can be batched, but the max should be 200 entries
  # which is the same limit as our API
  # first, get the IDs from the webhook
  ids = for index, occurrence of bundle.cleaned_request["occurrences"]
    occurrence["subject"]["task"]["id"]
  # second, make the request against the API for the JSON
  url = "tasks?ids=" + ids.join(",")
  bundle.request.headers.Authorization = "Bearer " + bundle.auth_fields.access_token
  response_content = Zap.make_get_request(bundle, url)
  # last, format json into array
  return Zap.process_task_response_content(response_content)

# Helper methods

Zap.process_task_response_content = (response_content) ->
  array = []
  for object in response_content.tasks
    # The format of this data MUST match the sample data format in triggers "Sample Result"
    # To get a sample, build a new object with good data and create a Zap, you should see
    # bundle output (from scripting editor quicklinks) once you try and add a field in the
    # Zap editor

    data = {}
    data.id = object.id
    data.created_at = object.created_at
    data.updated_at = object.updated_at
    data.name = object.name
    data.description = object.description
    data.priority = object.priority
    data.due_at = object.due_at
    data.completed_at = object.completed_at
    data.complete = object.complete
    data.is_private = object.is_private
    data.is_statute_of_limitations = object.is_statute_of_limitations
    data.assignee = Zap.transform_nested_attributes(object.assignee)
    data.assigner = Zap.transform_nested_attributes(object.assigner)
    data.matter = Zap.transform_nested_attributes(object.matter)
    array.push data
  array