require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = "RNAuth0Guardian"
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platform     = :ios, "10.0"
  s.source       = { :git => "https://github.com/Mukhammadali/react-native-auth0-guardian.git", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m,swift}"
  s.requires_arc = true
  s.preserve_paths = 'LICENSE', 'README.md', 'package.json', 'index.js'

  s.dependency "React"
  s.dependency "Guardian", ">= 1.0.0"
  #s.dependency "others"

end

  