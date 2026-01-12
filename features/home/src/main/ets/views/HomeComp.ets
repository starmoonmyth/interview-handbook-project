
import { authStore, BasicConstant, HdClockIn, hdHttp, HdSearch, HdUser } from '@itcast/basic'
import { CourseCardComp } from '../components/CourseCardComp'
import { CourseModel, CourseData } from '../models/CourseModel'
import { HomeDayQuestionComp } from '../components/HomeDayQuestionComp'
import { HomeQuestionCardComp } from '../components/HomeQuestionCardComp'
import { promptAction, router } from '@kit.ArkUI'
import { BusinessError } from '@ohos.base'
import { CourseService } from '../services/CourseService'

@Component
export struct HomeComp {
  @StorageProp('topHeight')
  topHeight: number = 0
  @StorageProp('user')
  user: HdUser = {} as HdUser
  scroller = new Scroller()
  @State
  isVisible: boolean = false
  @State
  opacityValue: number = 0
  @State
  areaHeight: number = 0
  @State recommendedList: CourseModel[] = []
  @State allCourseList: CourseModel[] = []
  @State filterCourseList: CourseModel[] = []
  @State searchKeyword: string = ''

  aboutToAppear(): void {
    this.getCourseList()
  }

  getCourseList() {
    CourseService.getCourseList().then(res => {
      let courses = res.data || []

      // 推荐课程：参加人数最多的前4个
      this.recommendedList = [...courses]
        .sort((a, b) => (b.studentCount || 0) - (a.studentCount || 0))
        .slice(0, 4)
      
      // 所有课程：按上传顺序（ID倒序）
      this.allCourseList = [...courses].sort((a, b) => b.id - a.id)
      this.filterCourseList = this.allCourseList
    })
  }

  scrollStatusBar(y: number) {
    if (y < this.areaHeight) {
      this.opacityValue = y / this.areaHeight
    } else {
      this.opacityValue = 1
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Row()
        .height(this.topHeight)
        .width('100%')
        .backgroundColor($r('app.color.white'))
        .opacity(this.opacityValue)
        .zIndex(1)
      Scroll(this.scroller) {
        Column() {
          Column() {
            Text('推荐课程')
              .width('100%')
              .fontWeight(500)
              .padding({ left: BasicConstant.SPACE_LG, bottom: BasicConstant.SPACE_MD, top: BasicConstant.SPACE_MD })

            Scroll() {
              Row({ space: BasicConstant.SPACE_MD }) {
                ForEach(this.recommendedList, (item: CourseModel) => {
                  CourseCardComp({ course: item })
                    .onClick(() => {
                      router.pushUrl({
                        url: 'pages/CourseDetailPage',
                        params: {
                          id: item.id,
                          title: item.title
                        }
                      })
                    })
                })
              }
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Off)
            .padding({ left: 16, right: 16, bottom: 12 })
            .edgeEffect(EdgeEffect.Spring)
          }
          .onAreaChange((_o, n) => {
            this.areaHeight = n.height as number
          })

          Column() {
            // Search Bar
            Search({ placeholder: '搜索课程' })
              .width('100%')
              .height(40)
              .backgroundColor('#F5F5F5')
              .placeholderColor(Color.Grey)
              .placeholderFont({ size: 14 })
              .textFont({ size: 14 })
              .margin({ bottom: 16 })
              .onChange((value: string) => {
                this.searchKeyword = value
                if (!value) {
                  this.filterCourseList = this.allCourseList
                } else {
                  this.filterCourseList = this.allCourseList.filter(item =>
                  item.title.toLowerCase().includes(value.toLowerCase())
                  )
                }
              })

            // Vertical Course List
            if (this.filterCourseList.length === 0) {
              Text('暂无课程')
                .fontSize(14)
                .fontColor('#999')
                .margin({ top: 20 })
                .width('100%')
                .textAlign(TextAlign.Center)
            } else {
              ForEach(this.filterCourseList, (item: CourseModel) => {
                Row() {
                  Image(item.cover)
                    .width(120)
                    .height(80)
                    .borderRadius(6)
                    .objectFit(ImageFit.Cover)
                    .backgroundColor('#F0F0F0')

                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontWeight(FontWeight.Medium)
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .layoutWeight(1)

                    Row() {
                      Text(item.teacherName && item.teacherName !== '' ? item.teacherName : item.teacher || '讲师')
                        .fontSize(12).fontColor('#999')
                    }
                    .width('100%')
                  }
                  .layoutWeight(1)
                  .height(80)
                  .padding({ left: 12, top: 4, bottom: 4 })
                  .justifyContent(FlexAlign.SpaceBetween)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .margin({ bottom: 16 })
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/CourseDetailPage',
                    params: { id: item.id, title: item.title }
                  })
                })
              })
            }
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 20 })
          .backgroundColor(Color.White)
          .width('100%')
        }
        .backgroundColor($r('app.color.common_gray_bg'))
        .alignItems(HorizontalAlign.Start)
        .padding({ top: this.topHeight })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .onScroll(() => {
        // if (this.isVisible) {
        //   windowManager.scrollStatusBar(this.scroller.currentOffset().yOffset)
        // }
        this.scrollStatusBar(this.scroller.currentOffset().yOffset)
      })

      // .onVisibleAreaChange([0, 1], (isVisible) => {
      //   this.isVisible = isVisible
      //   windowManager.scrollStatusBar(isVisible ? this.scroller.currentOffset().yOffset : 0)
      // })
    }
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}