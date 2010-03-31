require 'machinist/active_record'

Sham.name    { (1..10).collect { ('a'..'z').to_a.rand } }

Post.blueprint do
  name     { Sham.name }
  priority { Priority.find(:all).rand }
end