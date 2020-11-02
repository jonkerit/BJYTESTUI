## iOS UI SDK 源码打包 framework 集成

### 1、背景

- iOS 的 UI SDK 是源码开放的，[标准版本](https://git.baijiashilian.com/open-ios/BJLiveUI)默认会带有 [framwork](https://git.baijiashilian.com/open-ios/BJLiveUI/tree/master/frameworks) 的文件。**标准 UI SDK 对于不需要修改源码，集成远端 framwork 或者源码的客户可以直接使用**

- 对于为了快速集成，需要自己修改源码的客户，一般可以参考[源码集成文档](https://git.baijiashilian.com/open-ios/BJLiveUI/blob/master/wiki/%E7%9B%B4%E6%92%AD%20UI%20SDK%20%E6%BA%90%E7%A0%81%E9%9B%86%E6%88%90%20&%20%E8%87%AA%E5%AE%9A%E4%B9%89%E4%BF%AE%E6%94%B9%20.md)，进行修改后直接集成即可。**对于需要修改源码，然后本地源码集成的客户可以使用了**

- 特别的，对于使用 swift 的第三方库，或者本身是 swift 项目的客户，需要在修改完源码后，编译生成一个 framework 文件，根据需要本地集成或者上传到客户自己的 Git 等代码管理仓库后，远端或者本地集成。

- 文档下面将介绍针对需要修改完源码，编译 framework 的情况如何集成的解决方案。文档不会实时维护更新，需要开发者根据具体情况随机应变。

### 2、基本工具

下面是在开始前需要确保的一些基本开发工具，尽量保证工具都是最新的正式版，基于 Mac OS 平台介绍。

- Xcode。Mac OS 上 Xcode 的 App Store 地址：[https://apps.apple.com/cn/app/xcode/id497799835](https://apps.apple.com/cn/app/xcode/id497799835)。

- 安装 cocoapods 工具包。终端执行 `gem install cocoapods` 即可。参考官网 [https://cocoapods.org/](https://cocoapods.org/)。

- 安装 cocoapods-packager 工具包。终端执行 `gem install cocoapods-packager` 即可。

- 单独上传了 SDK 的源码的 Git 仓库。


### 3、podspec 文件配置

下面是标准版本的 UI SDK 的 [podspec](https://git.baijiashilian.com/open-ios/BJLiveUI/-/blob/master/BJLiveUI.podspec) 的内容。将基于标准 UI SDK 示例介绍。

![image](https://img.baijiayun.com/0baijiatools/f3aa862bf53640507dfdf0ec7553d564/podspec.png)

- 修改 `s.name` 和 `s.version` 为 SDK 的名字和版本号，在私有的 Git 仓库下，可以随意定义，只要不会冲突即可。 

- 修改 `s.source` 部分的 `:git => "https://git.baijiashilian.com/open-ios/BJLiveUI.git"` 内容为远端 SDK 的 Git 地址。

- 注释掉 `ss.subspec 'static' do |ss|` 到最近的 `end` 区域，修改 `s.default_subspecs = ['static']` 为 `s.default_subspecs = ['static.source']`。

- 修改 `s.subspec 'static.source'` 的内容，分别设置好修改过的 SDK 需要暴露的头文件 `ss.public_header_files`，SDK 的源码文件 `ss.source_files`，SDK 的资源文件 `ss.resource_bundles`。

- SDK 的一些设置，以及依赖的其他代码库、framework，libraries等按需添加、删除、修改。

### 4、生成 framwork 文件

- 将修改好的 podspec 文件， 提交到 Git 仓库后，给此次提交 SDK 添加 tag，tag 为 SDK 的 `s.version` 的数字。

- 构建管理 SDK 版本的 repo 仓库，直接初始化一个空的 Git 仓库，例如地址为 `http://https://github.com/Afirefish/spec`，执行 `pod repo add repo名字 https://github.com/Afirefish/spec` 即可。`repo名字` 可以自定义，添加之后可以通过 `pod repo` 命令查看本地的 repo 列表。

- 终端 cd 进入 SDK 文件夹内，使得 podspec 文件在当前工作区，执行 `pod spec lint  podspec文件名 --sources=repo名字,baijiashilian-open-ios-specs,cocoapod --use-libraries --allow-warnings --verbose --skip-import-validation` 。`podspec文件名` 为 SDK 的文件名，`repo名字` 为上一步创建的 repo名字，后续的 `baijiashilian-open-ios-specs` 是我们标准 SDK 的 repo 仓库，`cocoapod ` 是 cocoapod 的 GitHub 的 repo 仓库，这几个 repo 根据具体情况调整即可。后续的参数是标准版本需要使用的，可以根据实际情况调整。

- 等待上一步执行完毕，如果出现了错误需要开发者自行根据错误提示进行调整。成功之后执行 `pod repo push repo名字 podspec文件名 --sources=repo名字,baijiashilian-open-ios-specs,cocoapod --use-libraries --allow-warnings --verbose --skip-import-validation `，内容和参数与上一步的基本一致。

- 等待上一步执行完毕，如果出现了错误需要开发者自行根据错误提示进行调整。成功之后可以在 repo 仓库中看到发布的 SDK 了。如果是源码远端集成的情况，此时只要在 podfile 中写上 `pod 'SDK名字', 'SDK版本号'`，执行 `pod update` 即可集成，但是如果需要集成 framework，还需要继续调整。**对于需要修改源码，远端集成源码的客户可以使用了**。

- 执行 `pod package podspec文件名 --embedded --no-mangle --exclude-deps --spec-sources=https://git.baijiashilian.com/open-ios/specs.git,https://github.com/CocoaPods/Specs.git —verbose ` 将会生成 framwork，`--spec-sources=` 后是 SDK 依赖的 repo 仓库的地址，根据具体的情况调整。 

- 等待上一步执行完毕，如果出现了错误需要开发者自行根据错误提示进行调整。成功之后将会生成一个带有 SDK 名字和版本号的文件夹，拿出其中的 `.framework` 文件夹，放入一个固定的路径目录下，标准 SDK 在相对 podspec 文件的路径的 `frameworks` 目录下。

### 5、配置集成 framework 的 podspec 文件

- 复原注释掉的 `ss.subspec 'static' do |ss|` 到最近的 `end` 区域的改动，修改 `s.default_subspecs = ['static.source']` 为 `s.default_subspecs = ['static']`。

- 修改 `ss.preserve_paths` 为 framwork 的位置，`ss.source_files` 和 `ss.public_header_files` 为 framwork 头文件位置，`ss.resources` 为 framwork 资源文件的位置，`ss.vendored_frameworks` 为 framwork 的位置。

- 提交改动之后，对于本地集成 framwork 的客户，此时只要在 podfile 中写上 `pod 'SDK名字', 'SDK版本号'`，执行 `pod update` 即可集成，但是如果需要远端集成 framework，还需要继续调整。**对于需要修改源码，本地集成 framework 的客户可以使用了**。

### 5、发布带有 framework 的 SDK

- 将上述的全部改动提交到远端 SDK 的仓库后，删除源码编译 framwork 的 tag，重新添加 tag 到最新的提交上，然后执行 `pod repo push repo名字 podspec文件名 --sources=repo名字,baijiashilian-open-ios-specs,cocoapod --use-libraries --allow-warnings --verbose --skip-import-validation `，具体情况参考发布源码的情况即可。

- 等待发布成功之后，此时只要在 podfile 中写上 `pod 'SDK名字', 'SDK版本号'`，执行 `pod update` 即可集成 framwork 了。
**对于修改源码，需要远端集成 framework 的客户可以使用了**。

 

 