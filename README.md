# YSNetwork

[![CI Status](https://img.shields.io/travis/OneKnife/YSNetwork.svg?style=flat)](https://travis-ci.org/OneKnife/YSNetwork)
[![Version](https://img.shields.io/cocoapods/v/YSNetwork.svg?style=flat)](https://cocoapods.org/pods/YSNetwork)
[![License](https://img.shields.io/cocoapods/l/YSNetwork.svg?style=flat)](https://cocoapods.org/pods/YSNetwork)
[![Platform](https://img.shields.io/cocoapods/p/YSNetwork.svg?style=flat)](https://cocoapods.org/pods/YSNetwork)

基于Alamofire的再封装，将每个网络请求封装成对象，提供更方便的网络请求配置

主要实现的功能：

- 更方便的网络请求超时时间设置
- 添加网络请求的公用参数
- 支持缓存，可自定义缓存时间，是否支持缓存、先使用缓存后请求数据等功能
- 统一设置服务器地址
- 更方便的自定义 requset headerFields

所有功能都可设置默认设置和单条独立配置。

之后根据需求会添加其他功能。

## 安装

YSNetwork 可通过 [CocoaPods](https://cocoapods.org). 安装
只需要在Podfile中加入下面的代码:

```ruby
pod 'YSNetwork'
```

## 作者

OneKnife, melody@hitour.cc

## 协议

YSNetwork is available under the MIT license. See the LICENSE file for more info.
