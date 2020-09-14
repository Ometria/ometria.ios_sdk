Pod::Spec.new do |s|
  s.name                = 'Ometria'
  s.version             = '1.0'
  s.module_name         = 'Ometria'
  s.summary             = 'Ometria SDK for iOS (Swift)'
  s.source              = { :git => '', :tag => '' }
  s.license             = { :type => 'BSD' }
  s.author              = { 'Catalin Demian' => 'catalin.demian@tapptitude.com' }
  s.homepage            = 'http://ometria.com/'
  s.platform            = :ios, '10.0'
  s.frameworks          = 'UIKit', 'Foundation'
  s.source_files        = 'Ometria/Source/*.{swift}'
  s.resources           = 'Ometria/*.{xib}'
  s.header_mappings_dir = ''
  s.static_framework    = true
  s.dependency 'Firebase/Messaging'
end
