Zap.find_user = (bundle, query, not_found, subscription_plan) ->
  user = null

  if isFinite(query)
    user ?= Zap.find_user_by_id(bundle, query, subscription_plan)
  user ?= Zap.find_user_by_query(bundle, query, subscription_plan)
    
  unless user?
    switch not_found
      when "cancel"
        throw new StopRequestException("Could not find user.")
      when "ignore"
        null #noop
      else
        throw new HaltedException('Could not find user');
  
  user

Zap.find_user_by_id = (bundle, id, subscription_plan) ->
  user = null
  if isFinite(id)
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/users?ids=#{encodeURIComponent(id)}#{Zap.find_user_subscription_plan_to_query(subscription_plan)}&limit=1")
    if response.users.length > 0
          user = response.users[0]
  user

Zap.find_user_by_query = (bundle, query, subscription_plan) ->
  user = null
  if Zap.valueExists query
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/users?query=#{encodeURIComponent(query)}#{Zap.find_user_subscription_plan_to_query(subscription_plan)}&limit=1")
    if response.users.length > 0
      user = response.users[0]
  user

Zap.find_user_subscription_plan_to_query = (subscription_plan) ->
  if Zap.valueExists subscription_plan
    subscription_plan = "&subscription_plan=#{encodeURIComponent(subscription_plan)}"
  else
    subscription_plan = ""
  subscription_plan