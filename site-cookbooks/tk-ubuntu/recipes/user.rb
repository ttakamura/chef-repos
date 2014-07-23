user_account 'takamura' do
  ssh_keys ['ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1ySeEp8o54S7SRYU2L0RCRAfPV2521AMZDSWltbLpZabpla/kV6L8CZ48M/nlLpMwofdUQyEy5v3GOFFRSrwGedF0zH5F8EEPpXzh2LexIqYulFHaAJI2vdCiAsTlDBitRprh4ybnSn08JXgDOMsxjWeBMzRnfGQ6rms9VJpGSmbzq3Jb38nglnhUvy0m+uKrukgr8P8OTfJDAtfqAU3yr0u45ivFrBwjKS2BrmVvfii7F9R2DORg7SUYSsf8kqfRQcyOAnz+iD2+4P3B4i2OdVWiA6BujuU+v8HXM3m6zYXNZGsa2Q/gaqHWo/HUuFqDD+J/JGaTY26zX/7uXYRB tatsuya@TakamuraMacBookAir-1784.local'] # home_id_rsa
end

sudo 'takamura' do
  user 'takamura'
  nopasswd true
end

group 'adm' do
  members ['syslog', 'ubuntu', 'takamura']
  action :modify
end
