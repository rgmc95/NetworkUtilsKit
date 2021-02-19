inhibit_all_warnings!
use_frameworks!

platform :ios, '10.0'

target 'NetworkUtilsKit' do
  
  pod 'UtilsKit'		  , '~> 2.0.6'
  pod 'PromiseKit'	      , '~> 6.13'
  
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['SWIFT_VERSION'] = '5.3'
            
            config.build_settings['EXPANDED_CODE_SIGN_IDENTITY'] = ""
            config.build_settings['CODE_SIGNING_REQUIRED'] = "NO"
            config.build_settings['CODE_SIGNING_ALLOWED'] = "NO"
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = 10.0
        end
    end
end
