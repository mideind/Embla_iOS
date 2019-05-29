platform :ios, '9.2'

ENV["COCOAPODS_DISABLE_STATS"] = "true"

inhibit_all_warnings!
use_frameworks!

target 'GreynirApp' do

  pod 'googleapis', :path => '.'
  pod 'AFNetworking', '~> 3.0'
  pod 'AWSMobileClient'
  pod 'AWSPolly'

end


post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '5.0'
    end
end
