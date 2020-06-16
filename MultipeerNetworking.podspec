Pod::Spec.new do |s|
  s.name             = 'MultipeerNetworking'
  s.version          = '1.0.0'
  s.license          = 'MIT'
  s.summary          = 'MultipeerNetworking'
  s.homepage         = 'https://github.com/dbagwell/MultipeerNetworking'
  s.author           = 'David Bagwell'
  s.source           = { :git => 'https://github.com/dbagwell/MultipeerNetworking.git', :tag => '1.0.0' }

  s.ios.deployment_target = '11.0'
  s.swift_version = '5.0'

  s.source_files     = 'Source/**/*'

  s.dependency 'Rebar'

end
