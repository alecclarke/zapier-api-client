Zap.make_get_request =  (bundle, resource_url) ->
  url = Zap.build_api_url(resource_url, bundle.auth_fields.top_level_domain)
  content = z.request(Zap.build_request(bundle, url, "GET", null)).content
  JSON.parse content