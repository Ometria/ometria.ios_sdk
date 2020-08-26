Pod::Spec.new do |s|
  s.name                = 'Ometria'
  s.version             = '1.0.1'
  s.module_name         = 'Ometria'
  s.summary             = 'Ometria SDK for iOS (Swift)'
  s.source              = { :git => '', :tag => '' }
  s.license             = { :type => 'BSD' }
  s.author              = { 'Catalin Demian' => 'catalin.demian@tapptitude.com' }
  s.homepage            = 'http://ometria.com/'
  s.platform            = :ios, '10.0'
  s.frameworks          = 'UIKit', 'Foundation'
  s.source_files        = 'Ometria/Source/*.{swift}', 'Ometria/Source/Configuration/*.{swift}', 'Ometria/Source/Automatic Tracking/', 'Ometria/Source/Automatic Tracking/Push Notifications', 'Ometria/Source/Automatic Tracking/App Lifecycle', 'Ometria/Source/Automatic Tracking/Screen Views', 'Ometria/Source/Logger', 'Ometria/Source/Model', 'Ometria/Source/Cache', 'Ometria/Source/Notifications', 'Ometria/Source/Event Handling', 'Ometria/Source/Error', 'Ometria/Source/Network', 'Ometria/Source/Util'
  s.resources           = 'Ometria/*.{xib}'
  s.header_mappings_dir = ''
  s.static_framework    = true
  s.dependency 'Firebase/Messaging'
end
