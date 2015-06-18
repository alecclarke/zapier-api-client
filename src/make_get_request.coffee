Zap.make_get_request =  (bundle, resource_url) ->
  url = Zap.build_api_url(bundle.auth_fields.domain, resource_url)
  content = z.request(Zap.build_request(bundle, url, "GET", null)).content
  JSON.parse content