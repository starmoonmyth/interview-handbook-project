import { router, promptAction } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { NetworkConfig, logger } from '@itcast/basic';

@Entry
@Component
struct WebBrowserPage {
  @State url: string = ''
  @State title: string = ''
  @State fileType: string = ''
  @State isDownloaded: boolean = false
  
  controller: webview.WebviewController = new webview.WebviewController()

  aboutToAppear() {
    // 开启调试
    webview.WebviewController.setWebDebuggingAccess(true);

    const params = router.getParams() as Record<string, string>
    if (params) {
      let fileUrl = params.url
      if (fileUrl && (!fileUrl.startsWith('http') || fileUrl.includes('localhost') || fileUrl.includes('127.0.0.1'))) {
         // 处理相对路径、localhost、127.0.0.1
         const baseUrlRoot = NetworkConfig.BASE_URL.replace(/\/hm\/?$/, '/')
         let cleanPath = ''
         const localhostRegex = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//
         if (localhostRegex.test(fileUrl)) {
             cleanPath = fileUrl.replace(localhostRegex, '')
         } else {
             cleanPath = fileUrl.startsWith('/') ? fileUrl.substring(1) : fileUrl
         }
         fileUrl = baseUrlRoot + cleanPath
      }
      this.url = fileUrl
      this.title = params.title
      this.fileType = params.type || '' // 获取文件类型 (WORD/PDF)
      logger.info('WebBrowserPage', `Init: url=${this.url}, type=${this.fileType}`)
    }
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.ic_public_arrow_left'))
          .width(24)
          .height(24)
          .onClick(() => {
            router.back()
          })
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 16 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .layoutWeight(1)
        
        // 下载/打开按钮
        Text(this.isDownloaded ? '打开' : '下载')
          .fontSize(14)
          .fontColor('#007DFF')
          .onClick(() => {
             if (this.isDownloaded) {
                // TODO: 调用系统能力打开本地文件
                promptAction.showToast({ message: '正在打开文件...' })
             } else {
                promptAction.showToast({ message: '开始下载...' })
                // 触发 Web 组件的下载
                this.controller.loadUrl(this.url)
             }
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .border({ width: { bottom: 1 }, color: '#EEEEEE' })

      // 内容区域
      if (this.fileType === 'WORD') {
        // Word 文件：不预览，显示下载提示
        Column() {
          Image($r('app.media.ic_public_file_filled'))
            .width(80)
            .height(80)
            .fillColor('#007DFF')
            .margin({ bottom: 16 })
          Text(this.isDownloaded ? '文件已下载' : '该文件需要下载后查看')
            .fontSize(16)
            .fontColor('#333333')
            .margin({ bottom: 8 })
          Button(this.isDownloaded ? '打开文件' : '点击下载')
            .onClick(() => {
               if (this.isDownloaded) {
                  promptAction.showToast({ message: '正在打开...' })
               } else {
                  promptAction.showToast({ message: '开始下载...' })
                  // 通过不可见的 Web 组件触发下载
                  this.controller.loadUrl(this.url)
               }
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        
        // 隐藏的 Web 组件用于触发下载
        Web({ src: '', controller: this.controller })
          .height(0)
          .onDownloadStart((event) => {
             if (event) {
               logger.info('WebBrowserPage', `Download started: ${event.url}`)
               promptAction.showToast({ message: '下载开始...' })
               // 模拟下载完成 (真实场景需对接下载任务)
               setTimeout(() => {
                 this.isDownloaded = true;
                 promptAction.showToast({ message: '下载完成' })
               }, 2000)
             }
          })
          
      } else {
        // PDF 或其他：尝试预览
        // 针对 PDF 灰色问题：通常是因为 Web 组件对 PDF 的原生支持有限或需要特定插件
        // 尝试使用 Google Docs Viewer 或 Mozilla PDF.js 是一种通用方案，但在内网环境下不可用
        // 这里尝试配置 domStorage 和 mixedMode 增强兼容性
        Web({ src: this.url, controller: this.controller })
          .width('100%')
          .layoutWeight(1)
          .domStorageAccess(true)
          .mixedMode(MixedMode.All) // 允许混合内容
          .fileAccess(true)
          .imageAccess(true)
          .onDownloadStart((event) => {
            if (event) {
               logger.info('WebBrowserPage', `PDF Download: ${event.url}`)
               promptAction.showToast({ message: '正在下载...' })
               this.isDownloaded = true;
            }
          })
          .onErrorReceive((event) => {
             logger.error('WebBrowserPage', `Web Error: ${JSON.stringify(event)}`)
             // 如果预览失败，自动切换为下载模式提示
          })
      }
    }
    .width('100%')
    .height('100%')
  }
}
