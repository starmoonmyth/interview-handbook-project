import { BasicConstant, HdSkeleton, HdSkeletonType, HdUser } from '@itcast/basic'
import { CourseModel, CourseService, ChapterData, StudentProgressData, CourseData } from '@itcast/home'
import { router } from '@kit.ArkUI'
import { emitter } from '@kit.BasicServicesKit'

@Component
export struct ProjectComp {
  @State list: CourseModel[] = []
  @StorageProp('topHeight') topHeight: number = 0
  @StorageProp('user') user: HdUser = {} as HdUser
  @State loading: boolean = true

  aboutToAppear(): void {
    this.loadData()
    emitter.on({ eventId: 10001 }, () => {
      this.loadData()
    })
    // 监听登录/退出事件
    emitter.on({ eventId: 100401 }, () => {
      this.loadData()
    })
  }

  loadData() {
    this.loading = true
    // Fix: If user is not logged in, clear list immediately
    if (!this.user.id || !this.user.token) {
      this.list = []
      this.loading = false
      return
    }

    CourseService.getMyCourses()
      .then(res => {
        // 后端已经返回了准确的 progress (0-100)
        // 直接映射为 CourseModel，构造函数会自动处理 URL 和默认值
        // Fix: Cast item to CourseData to allow class construction (arkts-no-structural-typing)
        this.list = (res.data || []).map(item => new CourseModel(item as CourseData))
      })
      .catch((err: Error) => {
        // console.error('ProjectComp: getMyCourses failed', err.message)
        // Fix: Clear list on error (e.g. 401 Unauthorized after logout/token expiry)
        this.list = []
      })
      .finally(() => {
        this.loading = false
      })
  }

  @Builder
  CourseItemBuilder(item: CourseModel) {
    Row({ space: BasicConstant.SPACE_MD }) {
      Image(item.cover || $r('app.media.ic_public_image'))
        .size({ width: 100, height: 70 })
        .borderRadius(4)
        .objectFit(ImageFit.Cover)
      
      Column({ space: 4 }) {
        Text(item.title)
          .fontSize(16)
          .fontWeight(500)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        Text(`讲师: ${item.teacherName && item.teacherName !== '' ? item.teacherName : item.teacher}`)
          .fontSize(12)
          .fontColor('#999999')
        
        Blank()

        Row() {
          Text(`进度: ${item.progress || 0}%`)
             .fontSize(12)
             .fontColor('#007DFF')
        }
      }
      .layoutWeight(1)
      .height(70)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .onClick(() => {
       // Navigate to CourseDetail
       // console.info(`ProjectComp: Navigate to CourseDetail, id=${item.id}, title=${item.title}`)
       router.pushUrl({
         url: 'pages/CourseDetailPage',
         params: { id: item.id, title: item.title }
       })
    })
  }

  build() {
    Column() {
      Text('我的课堂')
        .height(44)
        .width('100%')
        .fontWeight(500)
        .textAlign(TextAlign.Center)
        .border({ width: { bottom: 1 }, color: '#EEEEEE' })
        .margin({ top: this.topHeight })
        .backgroundColor(Color.White)
      
      List() {
        if (this.loading) {
           ForEach(new Array(3).fill(0), () => {
             ListItem() {
               HdSkeleton({ rows: 2, type: HdSkeletonType.IMAGE })
                 .margin({ top: 10, bottom: 10 })
             }
           })
        } else if (this.list.length > 0) {
           ForEach(this.list, (item: CourseModel) => {
             ListItem() {
               this.CourseItemBuilder(item)
             }
           })
        } else {
           ListItem() {
             Column() {
               Text('暂无课程')
                 .fontSize(14)
                 .fontColor('#999999')
                 .margin({ top: 100 })
               Button('去选课')
                 .margin({ top: 20 })
                 .onClick(() => {
                   // Switch to Home Tab (index 0)
                   // We need a way to switch tabs globally. 
                   // Usually via Emitter or AppStorage.
                   // Index.ets listens to eventId: 10000
                   import('@kit.BasicServicesKit').then(kit => {
                     kit.emitter.emit({ eventId: 10000 }, {
                       data: { activeIndex: 0 }
                     })
                   })
                 })
             }
             .width('100%')
             .alignItems(HorizontalAlign.Center)
           }
        }
      }
      .divider({
        strokeWidth: 1,
        color: '#EEEEEE'
      })
      .layoutWeight(1)
      .width('100%')
    }
  }
}
