Pod::Spec.new do |s|
  s.name                = 'Ometria'
  s.version             = '1.0'
  s.module_name         = 'Ometria'
  s.license             = 'MIT'
  s.summary             = 'Ometria SDK for iOS (Swift)'
  s.homepage            = 'http://ometria.com/'
  s.author              = { 'Ometria Inc' => 'email@ometria.com' }
  s.source              = { :git => 'https://github.com/Ometria/ometria.ios_sdk.git',
                            :tag => 'v#{s.version}' }
  s.platform            = :ios, '10.0'
  s.frameworks          = 'UIKit', 'Foundation'
  s.source_files        = 'Ometria/**/*.{swift}'
  s.resources           = 'Ometria/*.{xib}'
  s.static_framework    = true
  s.dependency 'FirebaseMessaging'
end
