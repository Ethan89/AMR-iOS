#
#  Be sure to run `pod spec lint amr-ios.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "amr-ios"
  s.version      = "0.0.9"
  s.summary      = "amr-ios是Opencore-amr的iOS版本"

  s.description  = <<-DESC
amr-ios是Opencore-amr的iOS版本, 基于Opencore-amr 0.1.15
                   DESC

  s.homepage     = "https://github.com/Ethan89/AMR-iOS"
  s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = { "Eth4n" => "yaofeng.guo@gmail.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/Ethan89/AMR-iOS.git", :tag => "#{s.version}" }

  s.source_files  = 'opencore-amr-ios/*.{h,m}', 'opencore-amr-ios/include/**/*'

  s.vendored_libraries = ['opencore-amr-ios/lib/libopencore-amrnb.a',
                          'opencore-amr-ios/lib/libopencore-amrwb.a']

  s.requires_arc = false

end
