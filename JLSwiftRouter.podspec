Pod::Spec.new do |s|
  s.name = "JLSwiftRouter"
  s.version = "2.0.0"
  s.license = { :type => "MIT", :file => "LICENSE" }
  s.summary = "A URL Router for iOS, written in Swift 3"
  s.homepage = "https://github.com/skyline75489/SwiftRouter"
  s.authors = { "Chester Liu" => "skyline75489@outlook.com" }
  s.source = { :git => "https://github.com/skyline75489/SwiftRouter.git", :tag => s.version }
  s.source_files = "Source/*"

  s.ios.deployment_target = '8.0'
end
