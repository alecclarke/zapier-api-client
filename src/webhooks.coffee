################################################################################
#### Zapier hooks
################################################################################

Zap.pre_subscribe = (bundle) ->
  payload = {web_hook_subscription: {url: bundle.target_url, event_type: bundle.event, secret: ""}}
  return {
    url: Zap.build_api_url(bundle.auth_fields.domain, "web_hook_subscriptions"),
    method: "POST",
    auth: bundle.request.auth,
    headers: bundle.request.headers,
    params: {},
    data: JSON.stringify(payload)
  }

Zap.post_subscribe = (bundle) ->
  result = JSON.parse(bundle.response.content)
  return {"id": result["web_hook_subscription"]["id"]}

Zap.pre_unsubscribe = (bundle) ->
  return {
    url: Zap.build_api_url(bundle.auth_fields.domain, "web_hook_subscriptions/" + bundle.subscribe_data["id"]),
    method: "DELETE",
    auth: bundle.request.auth,
    headers: bundle.request.headers,
    params: bundle.request.params,
    data: bundle.request.data
  }

################################################################################
#### Helper methods
################################################################################

Zap.get_content_from_skinny_hook = (bundle, object_name, api_url_name) ->
  # we use skinny webhooks, so we need to get the real content for zapier
  # webhook notifications can be batched, but the max should be 200 entries
  # which is the same limit as our API
  # first, get the IDs from the webhook
  ids = for index, occurrence of bundle.cleaned_request["occurrences"]
    occurrence["subject"][object_name]["id"]
  # second, make the request against the API for the JSON
  url = api_url_name + "?ids=" + ids.join(",")
  bundle.request.headers.Authorization = "Bearer " + bundle.auth_fields.access_token
  response_content = Zap.make_get_request(bundle, url)
  return response_content