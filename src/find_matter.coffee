Zap.find_matter = (bundle, query, not_found) ->
  # first check if there is a matter #show for this query, ie it is a matter id
  matter = null
  if isFinite(query)
    response = Zap.make_get_request(bundle, "matters/#{query}")
    if response.matter?
      matter = response.matter
  unless matter?
    # using limit = 2 because of CLIO-18926
    response = Zap.make_get_request(bundle, "matters?display_number=#{encodeURIComponent(query)}&limit=2")
    if response.matters.length > 0
      matter = response.matters[0]
  
  unless matter
    switch not_found
      when "cancel"
        throw new StopRequestException("Could not find matter.")
      when "ignore"
        null #noop
      else
        throw new HaltedException('Could not find matter');
    
  matter