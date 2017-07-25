# coding: utf-8

Pod::Spec.new do |s|
  s.name         = "WeexImagePreview"
  s.version      = "0.0.1"
  s.summary      = "Weex Plugin"

  s.description  = <<-DESC
                   Weexplugin Source Description
                   DESC

  s.homepage     = "https://github.com"
  s.license = {
    :type => 'Copyright',
    :text => <<-LICENSE
            copyright
    LICENSE
  }
  s.authors      = {
                     "愚远" =>"zhenxing.tzx@alibaba-inc.com"
                   }
  s.platform     = :ios
  s.ios.deployment_target = "8.0"

  s.source       = { :git => 'git@gitlab.alibaba-inc.com:IIC-IP-FE/weex-image-preview.git', :tag => '0.0.4' }
  s.source_files  = "ios/Sources/*.{h,m,mm}"

  s.requires_arc = true
  s.dependency "WeexPluginLoader"
  s.dependency "WeexSDK"
  s.dependency "SDWebImage"
  s.dependency "MBProgressHUD"
end
