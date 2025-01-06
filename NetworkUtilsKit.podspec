Pod::Spec.new do |s|
  s.name = 'NetworkUtilsKit'
  s.version = '4.1.0'
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
      Copyright 2012 - 2025 RGMC . All rights reserved.
      LICENSE
  }
  s.homepage = "https://github.com/rgmc95/NetworkUtilsKit"
  s.author = "Romain Gjura & Michael Coqueret & David Douard"
  s.summary = "Swift Network Utilities"
  s.swift_version = '6.0'
  s.source =  { :git => "https://github.com/rgmc95/NetworkUtilsKit.git", :tag => "4.1.0" }
  s.default_subspec = 'Core'

  s.ios.deployment_target = '14.0'

  s.subspec 'Core' do |core|
    core.dependency 'UtilsKit/UtilsKitCore', '~> 4.1'
    core.source_files = 'Sources/**/*.{h,m,swift}'
  end

end

