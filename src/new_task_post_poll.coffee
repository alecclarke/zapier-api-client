Zap.new_task_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  Zap.process_task_response_content(results)

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
