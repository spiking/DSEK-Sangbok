# Uncomment this line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'

target 'DSEK-Sångbok' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  pod 'MBProgressHUD', '~> 0.9.2'
  pod 'Firebase/Core'
  pod 'Firebase/Database'
  pod 'Firebase/Auth'
  pod 'Alamofire', '~> 4.0'
  pod 'DZNEmptyDataSet'
  pod 'GSMessages'
  pod 'MGSwipeTableCell'
  pod 'AHKActionSheet'
#  pod 'XLActionController'
  # Pods for DSEK-Sångbok

  post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
  
end
