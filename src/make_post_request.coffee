Zap.make_post_request = (bundle, resource_url, data) ->
  url = Zap.build_api_url(resource_url, bundle.auth_fields.top_level_domain)
  JSON.parse z.request(Zap.build_request(bundle, url, "POST", data)).content