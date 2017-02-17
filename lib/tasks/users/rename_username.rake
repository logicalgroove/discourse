require 'wtf_lang'

task 'users:rename_username' => :environment do
  WtfLang::API.key = "540e806ba8f533223c2986f88bda1606"
  langs = {}
  User.where('username ~ ?', '^(\d)+$').all.each do |user|
    lang = user.name.lang
    langs[lang] = 0 unless langs[lang]
    langs[lang] += 1
    puts "#{user.username} - #{user.name} - #{lang}"
    if ['iw', 'yi'].include? lang
      real_name = user.email.split('@')[0]
      new_name = real_name
      postfix = 1
      while User.exists?(username: new_name) || User.exists?(username_lower: new_name.downcase)
        new_name = "#{real_name}#{postfix}"
        puts "generate new name [#{postfix}] - #{new_name}"
        postfix += 1
      end

      user.update_attribute(:username, new_name)
    end
  end
  puts langs
end
