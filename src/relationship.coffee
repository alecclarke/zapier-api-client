# Zapier hooks

Zap.create_relationship_pre_write = (bundle) ->
  outbound = JSON.parse(bundle.request.data)
  contact_id = null
  contact_data = null
  contact_response = Zap.make_get_request(bundle, "contacts?query=" + outbound.relationship.contact.email)
  if contact_response.contacts.length > 0
    contact_id = contact_response.contacts[0].id
  else
    contact_data = JSON.stringify(contact:
      type: "Person"
      name: outbound.relationship.contact.name
      first_name: outbound.relationship.contact.name.split(" ")[0]
      last_name: outbound.relationship.contact.name.split(" ")[1]
      email_addresses: [
        name: "Work"
        address: outbound.relationship.contact.email
      ]
    )
    contact_response = Zap.make_post_request(bundle, "contacts", contact_data)
    contact_id = contact_response.contact.id
  outbound = relationship:
    description: outbound.relationship.description
    matter:
      id: outbound.relationship.matter.id
    contact:
      id: contact_id
  bundle.request.data = JSON.stringify(outbound)
  bundle.request


# Helper methods