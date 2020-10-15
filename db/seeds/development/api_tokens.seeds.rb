ExternalApp.find_or_create_by(name: 'Client Testing') do |app|
  app.api_tokens.build(token: 'db9c21583ea98d16e42a73d9f78897c1ffc1dffcae781eb17f841cf421bd22b7a1a1228226437c5fdf6b6c9a8f537b17')
  app.contact_email = 'testing@psu.edu'
end
