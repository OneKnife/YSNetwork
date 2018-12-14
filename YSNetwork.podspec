#
# Be sure to run `pod lib lint YSNetwork.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YSNetwork'
  s.version          = '0.0.4'
  s.summary          = '基于Alamofire的再封装'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/OneKnife/YSNetwork'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'OneKnife' => 'melody@hitour.cc' }
  s.source           = { :git => 'https://github.com/OneKnife/YSNetwork.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  s.swift_version = '4.0'
  s.source_files = 'YSNetwork/Classes/*'
  
  # s.resource_bundles = {
  #   'YSNetwork' => ['YSNetwork/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Alamofire', '~> 4.7'
  # s.script_phase = { :name => 'CommonCrypto', :script => 'echo $PROJECT_DIR/install_common_crypto.sh', :execution_position => :before_compile }
  # s.script_phase = { :name => 'CommonCrypto', :script => 'sh $PROJECT_DIR/install_common_crypto.sh', :execution_position => :before_compile }
  s.script_phase = {
    :name => 'CommonCrypto',
    :script => 'COMMON_CRYPTO_DIR="${SDKROOT}/usr/include/CommonCrypto"
    if [ -f "${COMMON_CRYPTO_DIR}/module.modulemap" ]
      then
      echo "CommonCrypto already exists, skipping"
      else
      # This if-statement means we will only run the main script if the
      # CommonCrypto.framework directory doesn not exist because otherwise
      # the rest of the script causes a full recompile for anything
      # where CommonCrypto is a dependency
      # Do a "Clean Build Folder" to remove this directory and trigger
      # the rest of the script to run
      FRAMEWORK_DIR="${BUILT_PRODUCTS_DIR}/CommonCrypto.framework"
      if [ -d "${FRAMEWORK_DIR}" ]; then
        echo "${FRAMEWORK_DIR} already exists, so skipping the rest of the script."
        exit 0
      fi
      mkdir -p "${FRAMEWORK_DIR}/Modules"
      echo "module CommonCrypto [system] {
        header \"${SDKROOT}/usr/include/CommonCrypto/CommonCrypto.h\"
        export *
      }" >> "${FRAMEWORK_DIR}/Modules/module.modulemap"
      ln -sf "${SDKROOT}/usr/include/CommonCrypto" "${FRAMEWORK_DIR}/Headers"
    fi',
    :execution_position => :before_compile
  }

end
