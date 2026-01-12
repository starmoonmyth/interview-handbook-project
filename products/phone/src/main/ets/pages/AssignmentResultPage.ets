import { AssignmentResultComp } from '@itcast/home/src/main/ets/views/AssignmentResultComp'

@Entry
@Component
struct AssignmentResultPage {
  build() {
    Column() {
      AssignmentResultComp()
    }
    .height('100%')
    .width('100%')
  }
}
