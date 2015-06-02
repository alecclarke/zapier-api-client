Zap.new_task_completion_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  array = []

  for field in results.timeline_events
    if field.event_type is "firm_feed_task_completed"
      task = Zap.make_get_request(bundle, "tasks/" + field.subject.id)
      array.push
        actor_id: field.actor.id
        actor_name: field.actor.name
        task_id: task.task.id
        task_name:task.task.name
        task_description: task.task.description
        task_assigner_id: task.task.assigner.id
        task_assigner_name: task.task.assigner.name
        task_completion_date: task.task.completed_at
  

  array
