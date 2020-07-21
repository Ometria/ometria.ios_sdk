Pod::Spec.new do |s|
  s.name         = 'Ometria'
  s.version      = '1.0'
  s.summary      = 'Ometria SDK'
  s.source       = { :git => '', :tag => '' }
  s.license      = { :type => 'BSD' }
  s.author       = { 'Catalin Demian' => 'catalin.demian@tapptitude.com' }
  s.homepage     = 'http://ometria.com/'
  s.platform     = :ios, '11.0'
  s.source_files = 'Ometria/Source/*.{swift}', 'Ometria/Source/Configuration/*.{swift}', 'Ometria/Source/Automatic Tracking/', 'Ometria/Source/Automatic Tracking/Push Notifications'
  s.resources    = 'Ometria/*.{xib}'
  s.header_mappings_dir = ''
  s.frameworks   = 'UIKit'
end
