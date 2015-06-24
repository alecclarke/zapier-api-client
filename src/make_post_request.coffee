Zap.make_post_request = (bundle, resource_url, data) ->
  url = Zap.build_api_url(bundle.auth_fields.domain, resource_url)
  JSON.parse z.request(Zap.build_request(bundle, url, "POST", data)).content