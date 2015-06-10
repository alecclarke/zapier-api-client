Zap.create_group_pre_write = (bundle)->
  outbound = JSON.parse(bundle.request.data)
  array=[]
  type = outbound.group.type
  #get list of users 
  users_response = Zap.make_get_request(bundle,"users")
  #if group.type is attorney populate array with only "Attorney" users
  if type is "Attorney"
	  for field in users_response.users
		    if field.subscription_plan is "Attorneys"
		      array.push user_id: field.id
  else
  #if group.type is all populate array with all users
    for field in users_response.users
		    array.push user_id: field.id
  #create group instance
  outbound = group:
	  name: outbound.group.name
	  users: array
  bundle.request.data = JSON.stringify(outbound)
  #return bundle.request
  bundle.request
		
			