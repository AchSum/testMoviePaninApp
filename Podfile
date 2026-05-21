# Podfile
# testMoviePanin - iOS Movie App

platform :ios, '14.0'
use_frameworks!

target 'testMoviePanin' do
  # UI Layout DSL - replaces NSLayoutConstraint boilerplate
  pod 'SnapKit', '~> 5.7'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      config.build_settings['SWIFT_VERSION'] = '5.9'
    end
  end
end
