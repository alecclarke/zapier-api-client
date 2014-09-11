Zap.find_matter = (bundle, query, not_found) ->
  # first check if there is a matter #show for this query, ie it is a matter id
  matter = null
  if isFinite(query)
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/matters/#{query}")
    if response.matter?
      matter = response.matter
  unless matter?
    response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/matters?display_number=#{encodeURIComponent(query)}&limit=1")
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