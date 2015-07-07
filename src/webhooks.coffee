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
