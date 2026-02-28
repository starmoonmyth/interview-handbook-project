import { router, promptAction } from '@kit.ArkUI';
import { NetworkConfig, logger } from '@itcast/basic';

@Entry
@Component
struct VideoPlayPage {
  @State url: string = ''
  @State title: string = ''
  
  // 使用原生视频控制器
  controller: VideoController = new VideoController()

  aboutToAppear() {
    const params = router.getParams() as Record<string, string>
    logger.info('VideoPlayPage', `aboutToAppear, params: ${JSON.stringify(params)}`)
    if (params) {
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
      // 使用原生 Video 组件
      if (this.url) {
        Video({
          src: this.url,
          controller: this.controller
        })
          .width('100%')
          .layoutWeight(1)
          .autoPlay(true)
          .controls(true) // 显示默认控制条
          .objectFit(ImageFit.Contain)
          .onStart(() => {
            logger.info('VideoPlayPage', 'Video started')
          })
          .onError(() => {
            logger.error('VideoPlayPage', 'Video play error')
            promptAction.showToast({ message: '视频播放失败，请检查网络或格式' })
          })
      } else {
         // Loading 状态
         Column() {
           LoadingProgress()
             .width(50)
             .height(50)
             .color(Color.White)
         }
         .width('100%')
         .layoutWeight(1)
         .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
  }
}
