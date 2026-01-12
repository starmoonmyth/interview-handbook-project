import { router, promptAction } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { NetworkConfig, logger } from '@itcast/basic';

@Entry
@Component
struct VideoPlayPage {
  @State url: string = ''
  @State title: string = ''
  
  // 使用 Web 组件控制器
  controller: webview.WebviewController = new webview.WebviewController();

  aboutToAppear() {
    // 开启 Web 调试模式
    webview.WebviewController.setWebDebuggingAccess(true);

    const params = router.getParams() as Record<string, string>
    logger.info('VideoPlayPage', `aboutToAppear, params: ${JSON.stringify(params)}`)
    if (params) {
      // 禁用硬件加速，尝试解决 PIPELINE_ERROR_DECODE 问题
      // 注意：HarmonyOS Web 组件目前没有直接的 disableHardwareAcceleration API
      // 但我们可以尝试通过 URL 参数或者不一样的加载方式来规避
      this.resolveUrl(params.url);
      this.title = params.title
    }
  }

  onPageShow() {
    // 页面显示时的逻辑
  }

  /**
   * 解析 URL，处理相对路径
   * @param originUrl 原始 URL
   */
  resolveUrl(originUrl: string) {
    let videoUrl = originUrl
    if (!videoUrl) return

    // 处理相对路径、localhost、127.0.0.1
    if (!videoUrl.startsWith('http') || videoUrl.includes('localhost') || videoUrl.includes('127.0.0.1')) {
      // 移除 BASE_URL 末尾的 'hm/'，获取服务器根地址
      // 确保 baseUrlRoot 不以 / 结尾，方便后续拼接
      const baseUrlRoot = NetworkConfig.BASE_URL.replace(/\/hm\/?$/, '').replace(/\/$/, '')
      
      let cleanPath = ''
      // 匹配 http(s)://localhost(:port)/ 或 http(s)://127.0.0.1(:port)/
      const localhostRegex = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?\//
      
      if (localhostRegex.test(videoUrl)) {
         cleanPath = videoUrl.replace(localhostRegex, '')
      } else {
         // 移除开头的 /
         cleanPath = videoUrl.startsWith('/') ? videoUrl.substring(1) : videoUrl
      }
      
      videoUrl = `${baseUrlRoot}/${cleanPath}`
    }
    this.url = videoUrl
    logger.info('VideoPlayPage', `Resolved URL: ${this.url}`)
  }

  build() {
    Column() {
      // 1. 顶部导航栏
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
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)
      .zIndex(1)

      // 2. 视频播放区域
      // 直接使用 Web 组件加载视频 URL，由内核处理播放逻辑
      // 这种方式通常比注入 HTML 更稳定，且支持浏览器的原生视频播放器特性
      Web({ src: this.url, controller: this.controller })
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(Color.Black)
        .domStorageAccess(true)
        .mediaPlayGestureAccess(true)
        .onlineImageAccess(true)
        .imageAccess(true)
        .fileAccess(true)
        .databaseAccess(true)
        .javaScriptAccess(true)
        .mixedMode(MixedMode.All)
        .onPageBegin(() => {
          logger.info('VideoPlayPage', 'Web loading started')
        })
        .onPageEnd(() => {
          logger.info('VideoPlayPage', 'Web loading finished')
        })
        .onErrorReceive((event) => {
          logger.error('VideoPlayPage', `Web error: ${JSON.stringify(event)}`)
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
