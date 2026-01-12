import { authStore, HdSearch, HdTab, HdTabItem, logger, HdSkeleton, HdSkeletonType, HdResponse } from '@itcast/basic'
import { AssignmentModel, CourseModel } from '../models/CourseModel'
import { CourseService } from '../services/CourseService'
import { router, promptAction } from '@kit.ArkUI'

@Component
export struct ExamComp {
  @State
  sort: number = 0 // 0: 待提交, 1: 已完成
  @StorageProp('topHeight')
  topHeight: number = 0
  @State
  loading: boolean = true
  @State
  list: AssignmentModel[] = []
  
  // Cache all assignments
  allAssignments: AssignmentModel[] = []

  // Tab config
  tabConfig: HdTabItem[] = [
    { name: '待提交', value: 0 },
    { name: '已完成', value: 1 }
  ]

  aboutToAppear(): void {
    this.loadData()
  }

  loadData() {
    this.loading = true
    CourseService.getMyCourses()
      .then(async (res) => {
        if (!res.data || !Array.isArray(res.data)) {
          this.allAssignments = []
          this.filterList()
          this.loading = false
          return
        }
        const courses = res.data
        const promises = courses.map(async (course: CourseModel) => {
           try {
             return await CourseService.getExamList(course.id)
           } catch (e) {
             logger.error('ExamComp', `Get exam for course ${course.id} failed`, JSON.stringify(e))
             return { code: 500, message: 'error', data: [] } as HdResponse<AssignmentModel[]>
           }
        })
        const results = await Promise.all(promises)
        
        // Flatten results
        this.allAssignments = []
        results.forEach(res => {
          if (res.data) {
            this.allAssignments.push(...res.data)
          }
        })
        
        this.filterList()
        this.loading = false
      })
      .catch((err: Error) => {
        logger.error('ExamComp', 'Load data failed', JSON.stringify(err))
        promptAction.showToast({ message: `加载失败: ${err.message}` })
        this.loading = false
      })
  }

  filterList() {
    if (this.sort === 0) {
      // 待提交: NOT_STARTED, IN_PROGRESS
      // Also maybe 'ENDED' if not submitted? But usually ended means missed.
      // Let's assume pending = NOT_STARTED or IN_PROGRESS
      this.list = this.allAssignments.filter(item => 
        item.status === 'NOT_STARTED' || item.status === 'IN_PROGRESS'
      )
    } else {
      // 已完成: SUBMITTED, GRADED, ENDED
      this.list = this.allAssignments.filter(item => 
        item.status === 'SUBMITTED' || item.status === 'GRADED' || item.status === 'ENDED'
      )
    }
  }

  @Builder
  AssignmentItemBuilder(item: AssignmentModel) {
    Row() {
      Column() {
        Text(item.title)
          .fontSize(16)
          .fontWeight(500)
          .margin({ bottom: 8 })
        
        Row() {
          if (item.status === 'NOT_STARTED') {
             Text('未开始')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#CCCCCC')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'IN_PROGRESS') {
             Text('进行中')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#007DFF')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'ENDED') {
             Text('已截止')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#FF0000')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'SUBMITTED') {
             Text('已提交')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#00C853')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          } else if (item.status === 'GRADED') {
             Text('已批改')
               .fontSize(10)
               .fontColor('#FFFFFF')
               .backgroundColor('#00C853')
               .padding({ left: 4, right: 4, top: 2, bottom: 2 })
               .borderRadius(2)
               .margin({ right: 8 })
          }

          Text(`发布时间: ${item.createdAt}`)
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)
      
      Blank()
      
      Image($r('app.media.ic_public_arrow_right'))
        .width(16)
        .height(16)
        .fillColor('#CCCCCC')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .margin({ bottom: 12 })
    .onClick(() => {
      // 状态判断
      if (item.status === 'NOT_STARTED') {
        promptAction.showToast({ message: '作业尚未开始' })
        return
      }
      if (item.status === 'ENDED') {
         promptAction.showToast({ message: '作业已截止' })
         return
      }
      if (item.status === 'SUBMITTED' || item.status === 'GRADED') {
         // 跳转到结果详情页
         router.pushUrl({
           url: 'pages/AssignmentResultPage',
           params: { assignmentId: item.id, type: 'exam', title: item.title }
         })
         return
      }

      // 跳转到做题页面
      router.pushUrl({
        url: 'pages/AssignmentPracticePage',
        params: { assignmentId: item.id, title: item.title }
      })
    })
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        Text('我的考试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        HdSearch({ ph: '搜索考试', bg: $r('app.color.common_gray_bg') })
          .layoutWeight(1)
          .onClick(() => {
             // 搜索功能暂时保留或隐藏
             promptAction.showToast({ message: '搜索功能暂未开放' })
          })
      }
      .padding({ left: 16, right: 16 })
      .height(64)
      .margin({ top: this.topHeight })
      .backgroundColor(Color.White)

      // 标签页
      HdTab({
        tabConfig: this.tabConfig,
        lineWidth: 16,
        onTabChange: (item) => {
          this.sort = item.value as number
          this.filterList()
        }
      })

      // 列表
      List() {
        if (this.loading) {
           ForEach(new Array(3).fill(0), () => {
             ListItem() {
               HdSkeleton({ rows: 2 })
                 .margin({ top: 10, bottom: 10, left: 16, right: 16 })
             }
           })
        } else if (this.list.length > 0) {
           ForEach(this.list, (item: AssignmentModel) => {
             ListItem() {
               this.AssignmentItemBuilder(item)
             }
             .padding({ left: 16, right: 16 })
           })
        } else {
           ListItem() {
             Column() {
               Text('暂无考试')
                 .fontSize(14)
                 .fontColor('#999999')
                 .margin({ top: 100 })
             }
             .width('100%')
             .alignItems(HorizontalAlign.Center)
           }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
      .padding({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
