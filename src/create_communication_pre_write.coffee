Zap.create_communication_pre_write = (bundle) ->
  outbound = JSON.parse(bundle.request.data)
  sender_type = undefined
  sender_id = null
  receiver_type = undefined
  receiver_id = null
  # Search for existing User with email_receiver
  user_response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/users?query=" + outbound.communication.email_receiver)
  #
  #        If the returned User search is successful,
  #        then update the receiver_id and receiver_type with 
  #        the found User data.
  #        
  if user_response.users.length > 0
    receiver_id = user_response.users[0].id
    receiver_type = "User"
  # Search for existing Contact with email_receiver
  contact_response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/contacts?query=" + outbound.communication.email_receiver)
  #
  #         If the returned Contact search is successful,
  #         then update the receiver_id and receiver_type with 
  #         the found Contact data.
  #         
  if contact_response.contacts.length > 0
    receiver_id = contact_response.contacts[0].id
    receiver_type = "Contact"
  #
  #    If the email of the Communication's receiver isn't recognised as
  #    an existing User or Contact then a Contact is created using the 
  #    email and name of the receiverand the Communication's receiver 
  #    will be associated with it.(only if new_contact is true)
  #    
  if receiver_id is null and outbound.communication.new_contact is true
    receiver_data = JSON.stringify(contact:
      type: "Person"
      name: outbound.communication.receiver_name
      first_name: outbound.communication.receiver_name.split(" ")[0] # used to split the full name *clearly wont work in every situation
      last_name: outbound.communication.receiver_name.split(" ")[1] # used to split the full name *clearly wont work in every situation
      email_addresses: [
        name: "Work"
        address: outbound.communication.email_receiver
      ]
      )
    contact_response = Zap.make_post_request(bundle, "https://app.goclio.com/api/v2/contacts", receiver_data)
    receiver_id = contact_response.contact.id
    receiver_type = "Contact"
  # Search Users for existence of sender_id
  user_response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/users?query=" + outbound.communication.email_sender)
  #
  #        If the returned User search is successful,
  #        then update the sender_id and sender_type with 
  #        the found User data.
  #        
  if user_response.users.length > 0
    sender_id = user_response.users[0].id
    sender_type = "User"
  # Search Contacts for existence of email_sender
  contact_response = Zap.make_get_request(bundle, "https://app.goclio.com/api/v2/contacts?query=" + outbound.communication.email_sender)
  #
  #        If the returned Contact search is successful,
  #        then update the sender_id and sender_type with 
  #        the found Contact data.
  #        
  if contact_response.contacts.length > 0
    sender_id = contact_response.contacts[0].id
    sender_type = "Contact"
  #
  #        If the email of the Communication's sender isn't recognised as
  #        an existing User or Contact then a Contact is created and the
  #        Communication's sender will be associated with it.(only if new_contact is true)
  #        
  if sender_id is null and outbound.communication.new_contact is true
    sender_data = JSON.stringify(contact:
      type: "Person"
      name: outbound.communication.sender_name
      first_name: outbound.communication.sender_name.split(" ")[0]
      last_name: outbound.communication.sender_name.split(" ")[1]
      email_addresses: [
        name: "Work"
        address: outbound.communication.email_sender
      ]
      )
    contact_response = Zap.make_post_request(bundle, "https://app.goclio.com/api/v2/contacts", sender_data)
    sender_id = contact_response.contact.id
    sender_type = "Contact"
  #
  #        If sender_type is Contact and add_matter_sender is true  
  #        check the contact_id against matters for a matter_id 
  #
  if sender_type is "Contact" and outbound.communication.add_matter_sender is true
	  matter_id = Zap.make_get_request(bundle,"https://app.goclio.com/api/v2/matters?status=Open&client_id="+sender_id)
  	_.defaults matter_id.matters,[id:null]
  #
  #        If receiver_type is Contact and add_matter_receiver is true  
  #        check the contact_id against matters for a matter_id 
  #
	 if receiver_type is "Contact" and outbound.communication.add_matter_receiver is true
	   matter_id = Zap.make_get_request(bundle,"https://app.goclio.com/api/v2/matters?status=Open&client_id="+receiver_id)
  	 _.defaults matter_id.matters,[id:null]
  #
  #        Default values for outbound.communication. 
  #        Stops undefined variable references. 
  #        
   _.defaults outbound.communication,
     subject: null
     body: null
     matter:
       id: null
   #check for validity of receiver_id and sender_id
	 if receiver_id is null
		 throw new HaltedException("given receiver isn't a valid contact or user")
	 if sender_id is null
		 throw new HaltedException("given sender isn't a valid contact or user")
   #
   #        Reformat outbound data to be appropriate for 
   #        the Clio API Communications' data structure.
   #        
   outbound = communication:
     type: "EmailCommunication"
     subject: outbound.communication.subject
     body: outbound.communication.body
     matter:
       id: matter_id.matters[0].id
     senders: [
       id: sender_id
       type: sender_type
      ]
     receivers: [
       id: receiver_id
       type: receiver_type
      ]
   bundle.request.data = JSON.stringify(outbound)
   bundle.request
