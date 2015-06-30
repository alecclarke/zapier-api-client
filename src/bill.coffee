# Zapier Hooks

Zap.new_bill_post_poll = (bundle) ->
  results = JSON.parse(bundle.response.content)
  
  array = []
  for object in results.bills
    # The format of this data MUST match the sample data format in triggers "Sample Result"
    # To get a sample, build a new object with good data and create a Zap, you should see
    # bundle output (from scripting editor quicklinks) once you try and add a field in the
    # Zap editor

    data = {}
    data.id = object.id
    data.created_at = object.created_at
    data.updated_at = object.updated_at
    data.type = object.type
    data.number = object.number
    data.purchase_order = object.purchase_order
    data.currency = object.currency
    data.memo = object.memo
    data.start_at = object.start_at
    data.end_at = object.end_at
    data.issued_at = object.issued_at
    data.due_at = object.due_at
    data.original_bill_id = object.original_bill_id
    data.tax_rate = object.tax_rate
    data.secondary_tax_rate = object.secondary_tax_rate
    data.discount = object.discount
    data.discount_type = object.discount_type
    data.discount_note = object.discount_note
    data.balance = object.balance
    data.balance_with_interest = object.balance_with_interest
    data.total = object.total
    data.state = object.state
    data.client = Zap.transform_nested_attributes(object.client)
    array.push data
  array

# Helper methods