platform :ios, '10.0'

ENV["COCOAPODS_DISABLE_STATS"] = "true"

inhibit_all_warnings!
use_frameworks!

target 'Greynir' do
    pod 'googleapis', :path => '.'
    pod 'AFNetworking', '~> 3.0'
    pod 'SDWebImage', '~> 5.0'
    pod 'SCSiriWaveformView', '~> 1.1.1'
    pod 'AWSMobileClient'
    pod 'AWSPolly'
    pod 'SDRecordButton', '~> 1.0'
end


post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '5.0'
    end
end
