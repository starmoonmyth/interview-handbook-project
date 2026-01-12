import { authStore, getTimeText, HdClockIn, hdHttp, HdUser } from '@itcast/basic'
import { promptAction, router } from '@kit.ArkUI'
import { OptionalRouterParams, OptionalType } from './OptionalComp'
import { CourseService, AssignmentModel, ChapterData, StudentProgressData } from '@itcast/home'

interface Nav {
  icon: ResourceStr
  name: string
  onClick?: () => void
  other?: string
}

interface Tool {
  icon: ResourceStr
  name: string
  value?: string
  onClick?: () => void
}

class TaskCount {
  pending: number = 0
  completed: number = 0
  total: number = 0
}

@Component
export struct MineComp {
  @StorageProp('topHeight')
  topHeight: number = 0
  @StorageProp('user')
  @Watch('initData')
  user: HdUser = {} as HdUser
  @StorageProp('colorMode')
  colorMode: number = -1
  @State
  isPreview: boolean = false
  @State joinedCoursesCount: number = 0
  @State pendingTasksCount: number = 0
  @State passRate: string = '0%'

  aboutToAppear(): void {
    this.initData()
  }

  initData() {
    if (this.user && this.user.token) {
      CourseService.getStudyInfo().then(res => {
        if (res.data) {
          // 如果后端已经返回了百分号，就不需要再加了；或者后端返回的是数字，这里统一处理
          // 假设后端返回的是数字 (如 50)，则加 %；如果返回的是字符串且带 %，则直接使用
          // 根据 StudyInfoData 接口定义，passRate 是 number，所以这里通常应该是数字
          // 但根据用户反馈 "50%%"，说明可能后端返回了带%的字符串或者这里重复加了
          // 如果后端返回的是数字，我们加上 %；
          // 如果后端返回的已经是字符串形式 (如 "50%")，这里再加就会变成 "50%%"
          // 但 CourseModel.ets 定义是 number，所以应该是 res.data.passRate 是 number
          // 用户说"后端返回数据的时候就带了百分号"，那说明接口定义可能不准确，或者后端返回的数据类型是 string
          // 我们做个兼容处理
          const rate = res.data.passRate
          if (typeof rate === 'string' && (rate as string).includes('%')) {
             this.passRate = rate as string
          } else {
             this.passRate = rate + '%'
          }
          this.joinedCoursesCount = res.data.courseCount
          this.pendingTasksCount = res.data.pendingTasks
        } else {
          this.resetData()
        }
      }).catch(() => {
        this.resetData()
      })
    } else {
      // 未登录时清零
      this.resetData()
    }
  }

  resetData() {
    this.joinedCoursesCount = 0
    this.pendingTasksCount = 0
    this.passRate = '0%'
  }

  @Builder
  navBuilder(nav: Nav) {
    GridCol() {
      Column() {
        Image(nav.icon)
          .width(30)
          .aspectRatio(1)
          .margin({ bottom: 10 })
        Text(nav.name)
          .fontSize(14)
          .fontColor($r('app.color.common_gray_03'))
          .margin({ bottom: 4 })
        if (nav.other) {
          Row() {
            Text(nav.other)
              .fontSize(12)
              .fontColor($r('app.color.common_gray_01'))
            Image($r('sys.media.ohos_ic_public_arrow_right'))
              .width(12)
              .aspectRatio(1)
              .fillColor($r('app.color.common_gray_01'))
          }
        }
      }
      .onClick(() => {
        nav.onClick && nav.onClick()
      })
    }
  }

  @Builder
  toolsBuilder(tool: Tool) {
    Row() {
      Image(tool.icon)
        .width(16)
        .aspectRatio(1)
        .margin({ right: 12 })
      Text(tool.name)
        .fontSize(14)
      Blank()
      if (tool.value) {
        Text(tool.value)
          .fontSize(12)
          .fontColor($r('app.color.common_gray_01'))
      }
      Image($r('sys.media.ohos_ic_public_arrow_right'))
        .width(16)
        .aspectRatio(1)
        .fillColor($r('app.color.common_gray_01'))
    }
    .height(50)
    .width('100%')
    .padding({ left: 16, right: 10 })
    .onClick(() => {
      tool.onClick && tool.onClick()
    })
  }

  @Builder
  AvatarPreviewBuilder() {
    Image(this.user.avatar)
      .objectFit(ImageFit.Contain)
      .onClick(() => {
        this.isPreview = false
      })
  }

  @Builder
  dataBoardBuilder() {
    Row() {
      Column({ space: 4 }) {
        Text(this.pendingTasksCount.toString())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.pendingTasksCount > 0 ? '#fa711d' : $r('app.color.black')) // 高亮显示
        Text('待办任务')
          .fontSize(12)
          .fontColor($r('app.color.common_gray_01'))
      }
      .layoutWeight(1)
      .onClick(() => {
         // 跳转到考试Tab (Index 1)
         // 注意：这里需要通过 emitter 通知 Index 页面切换 Tab
         // 暂且保留点击反馈，具体跳转逻辑已在 TabBarComp 实现
      })

      Column({ space: 4 }) {
        Text(this.passRate)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('课程通过率')
          .fontSize(12)
          .fontColor($r('app.color.common_gray_01'))
      }
      .layoutWeight(1)

      Column({ space: 4 }) {
        Text(this.joinedCoursesCount.toString())
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
        Text('已修课程')
          .fontSize(12)
          .fontColor($r('app.color.common_gray_01'))
      }
      .layoutWeight(1)
    }
    .backgroundColor($r('app.color.white'))
    .borderRadius(8)
    .padding(16)
    .justifyContent(FlexAlign.SpaceAround)
  }

  build() {
    Column({ space: 16 }) {
      Row({ space: 12 }) {
        Image(this.user.avatar || $r('app.media.ic_mine_avatar'))
          .alt($r('app.media.ic_mine_avatar'))
          .width(55)
          .aspectRatio(1)
          .borderRadius(55)
          .bindContentCover($$this.isPreview, this.AvatarPreviewBuilder, {
            modalTransition: ModalTransition.ALPHA,
            backgroundColor: '#000000'
          })
          .onClick(() => {
            if (this.user.avatar) {
              this.isPreview = true
            }
          })
        if (this.user && this.user.token) {
          Column({ space: 4 }) {
            Text(this.user.nickName || this.user.username)
              .fontSize(18)
              .fontWeight(500)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row({ space: 4 }) {
              Text('编辑信息')
                .fontSize(12)
                .fontColor($r('app.color.common_gray_01'))
              Image($r('app.media.ic_mine_edit'))
                .width(12)
                .aspectRatio(1)
                .fillColor($r('app.color.common_gray_01'))
            }
            .onClick(() => {
              authStore.checkAuth({
                url: 'pages/ProfileEditPage'
              })
            })
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        } else {
          Text('立即登录')
            .fontSize(18)
            .fontWeight(500)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
            .onClick(() => {
              router.pushUrl({
                url: 'pages/LoginPage'
              })
            })
        }

      }
      .width('100%')
      .height(100)
      .margin({ top: this.topHeight })

      this.dataBoardBuilder()

      Column() {
        this.toolsBuilder({
          icon: $r('app.media.ic_mine_setting'), name: '设置', onClick: () => {
            authStore.checkAuth({
              url: 'pages/SettingsPage'
            })
          }
        })
      }
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)

    }
    .padding($r('app.float.common_gutter'))
    .backgroundColor($r('app.color.common_gray_bg'))
    .linearGradient({
      colors: [[this.colorMode === 1 ? '#007DFF' : '#007DFF', 0], [$r('app.color.common_gray_bg'), 0.3], [$r('app.color.common_gray_bg'), 1]]
    })
    .width('100%')
    .height('100%')
  }
}