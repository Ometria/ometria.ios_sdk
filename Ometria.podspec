Pod::Spec.new do |s|
  s.name                = 'Ometria'
  s.version             = '1.8.4'
  s.module_name         = 'Ometria'
  s.license             = 'MIT'
  s.summary             = 'Ometria SDK for iOS (Swift)'
  s.homepage            = 'http://ometria.com/'
  s.author              = { 'Al James' => 'platform+cocoapods@ometria.com' }
  s.source              = { :git => 'https://github.com/Ometria/ometria.ios_sdk.git', :tag => "v#{s.version}" } 
  s.swift_version       = '5.0'
  s.platform            = :ios, '11.0'
  s.frameworks          = 'UIKit', 'Foundation'
  s.source_files        = 'Sources/Ometria/**/*.{swift}'
  s.static_framework    = true
  s.dependency 'FirebaseMessaging'
end
