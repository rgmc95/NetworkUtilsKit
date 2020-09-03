Pod::Spec.new do |s|
  s.name = 'NetworkUtilsKit'
  s.version = '1.0.1'
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
      Copyright 2012 - 2019 RGMC . All rights reserved.
      LICENSE
  }
  s.homepage = "https://github.com/rgmc95/NetworkUtilsKit"
  s.author = "Romain Gjura & Michael Coqueret"
  s.summary = "Swift Network Utilities"
  s.swift_version = '5.1'
  s.source =  { :git => "https://github.com/rgmc95/NetworkUtilsKit.git", :tag => "1.0.1" }
  s.default_subspec = 'Core'

  s.ios.deployment_target = '10.0'

  s.subspec 'Core' do |core|
    core.dependency 'UtilsKit', '~> 2.0'
    core.source_files = 'NetworkUtilsKit/Core/**/*.{h,m,swift}'
  end

  s.subspec 'Promise' do |ext|
    ext.dependency 'NetworkUtilsKit/Core'
    ext.dependency 'PromiseKit', '~> 6.13'
    ext.source_files = 'NetworkUtilsKit/Promise/**/*.{h,m,swift}'
  end

end

