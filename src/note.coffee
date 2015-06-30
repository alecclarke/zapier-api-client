# Zapier hooks

Zap.create_contact_note_pre_write = (bundle) ->
  Zap.create_note_pre_write(bundle, "Contact")

Zap.create_matter_note_pre_write = (bundle) ->
  Zap.create_note_pre_write(bundle, "Matter")

# Helper methods

Zap.create_note_pre_write = (bundle, regarding_type) ->
  request_data = JSON.parse(bundle.request.data)
  object = request_data.note
  
  data = {}
  data.subject = object.subject
  data.detail = object.detail
  data.date = object.date
  
  if regarding_type == "Matter" && object.matter?
    matter = Zap.find_matter(bundle, object.matter.name, "cancel")
    if matter?
      data.regarding = {}
      data.regarding.type = regarding_type
      data.regarding.id = matter.id
  if regarding_type == "Contact" && object.contact?
    contact = Zap.find_or_create_contact(bundle, object.contact, object.contact.question)
    if contact?
      data.regarding = {}
      data.regarding.type = regarding_type
      data.regarding.id = contact.id
  
  bundle.request.data = JSON.stringify({"note": data})
  bundle.request