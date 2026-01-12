import { authStore, HdSearch, HdTab, HdTabItem } from '@itcast/basic'
import { InterviewListComp } from '../components/InterviewListComp'

interface Company {
  icon: ResourceStr
  count: number
}

@Component
export struct InterviewComp {
  @State
  left: number = 16
  @State
  sort: number | undefined = 0
  @StorageProp('topHeight')
  topHeight: number = 0
  // tab
  tabConfig: HdTabItem[] = [
    { name: '待提交', value: 0 },
    { name: '已完成', value: 1 }
  ]

  build() {
    Column() {
      Row({ space: 16 }) {
        Text('我的考试')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
        HdSearch({ ph: '搜索考试', bg: $r('app.color.common_gray_bg') })
          .layoutWeight(1)
          .onClick(() => {
            interface Params {
              questionBankType: 9 | 10
            }

            authStore.checkAuth({
              url: 'pages/SearchPage',
              params: ({ questionBankType: 9 }) as Params
            })
          })
      }
      .padding({ left: 16, right: 16 })
      .height(64)
      .margin({ top: this.topHeight })

      // 标签页
      HdTab({
        tabConfig: this.tabConfig,
        lineWidth: 16,
        onTabChange: (item) => {
          this.sort = item.value as number
        }
      })
      // 文章列表
      InterviewListComp({ sort: this.sort })
    }
    .width('100%')
    .height('100%')
  }
}