platform :ios, '13.0'

ENV["COCOAPODS_DISABLE_STATS"] = "true"

inhibit_all_warnings!
#use_frameworks!

target 'Embla' do
    pod 'googleapis', :path => '.'
    pod 'AFNetworking', '~> 4.0.1', :subspecs => ['Serialization', 'Security', 'NSURLSession']
    pod 'Reachability', '~> 3.2'
    pod 'YYImage', '~> 1.0.4'
    # pod 'EAIntroView'
end

post_install do |installer|
    installer.pods_project.targets.each do |t|
      t.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      end
    end
end
