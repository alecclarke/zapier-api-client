Zap.contact_note_pre_write = (bundle) ->
    outbound = JSON.parse(bundle.request.data)
    #Internal poll for Clio Contact with provided email_address
    # Creating readable JSON object for Clio Contact
    response = Zap.make_get_request(bundle, "contacts?query=" + outbound.notes.email)
    #var for contact id number
    contact_id = undefined
    # If contact doesn't exist create a new contact
    if response.contacts.length < 1
      data = bundle.action_fields
    #Outbound request for new Clio contact creation
      contact = JSON.stringify(contact:
        type: "Person"
        name: data.notes.name
        first_name: data.notes.name.split(" ")[0]
        last_name: data.notes.name.split(" ")[1]
        email_addresses: [
          name: "Work"
          address: data.notes.email
        ]
      )
      create_response = Zap.make_post_request(bundle, "contacts", contact)
      contact_id = create_response.contact.id
    else
    # if contact previously existed
      contact_id = response.contacts[0].id
    #
    #        Reformating data to fit Clio Notes' format. 
    #        If there are multiple Contacts with the 
    #        same email only the top Contact will be referred to 
    #        (assume there are unique email addresses).
    #        
    outbound = note:
      subject: outbound.notes.subject
      detail: outbound.notes.detail
      regarding:
        type: "Contact"
        id: contact_id
    bundle.request.data = JSON.stringify(outbound)
    bundle.request