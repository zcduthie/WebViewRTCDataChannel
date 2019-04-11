#
# Be sure to run `pod lib lint WebViewRTCDataChannel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WebViewRTCDataChannel'
  s.version          = '0.1.0'
  s.summary          = 'A simple working iOS RTCDataChannel built using WKWebView.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Rather than include the external native WebRTC iOS framework at https://webrtc.org/native-code/ios, this library leverages WebKit's inbuilt WebRTC functionality and exposes WebRTC functionality through the WKWebView control.
                       DESC

  s.homepage         = 'https://github.com/zcduthie/WebViewRTCDataChannel'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'zcduthie' => 'zcduthie@gmail.com' }
  s.source           = { :git => 'https://github.com/zcduthie/WebViewRTCDataChannel.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  
  s.ios.deployment_target = '11.0'

  s.source_files = 'WebViewRTCDataChannel/Classes/**/*'
  
  s.resource_bundles = {
    'WebViewRTCDataChannel' => ['WebViewRTCDataChannel/Assets/datachannel.html', 'WebViewRTCDataChannel/Assets/datachannel.js']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
