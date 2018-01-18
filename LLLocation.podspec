Pod::Spec.new do |s|
  s.name                      = 'LLLocation'
  s.module_name               = 'LLLocation'
  s.version                   = '0.0.1'
  s.summary                   = 'Simple get location on iOS device. Write in swift4.'
  s.homepage                  = "https://github.com/Kila2/LLLocation"
  s.license                   = 'MIT'
  s.author                    = { "Kila2" => "277014717@qq.com" }
  s.platform                  = :ios, '8.0'
  s.ios.deployment_target     = '8.0'
  s.requires_arc              = true
  s.source                    = { :git => 'https://github.com/Kila2/LLLocation.git', :tag => s.version.to_s }
  s.source_files              = 'LLLocation/LLLocation/**/*.{h,swift}'
# s.resources                 = 'LLLocation/LLLocation/*.xcassets'
end