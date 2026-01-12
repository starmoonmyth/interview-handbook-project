import { PasswordEditComp } from '@itcast/mine';

@Entry
@Component
struct PasswordEditPage {
  @StorageProp('bottomHeight')
  bottomHeight: number = 0

  build() {
    Column() {
      PasswordEditComp()
    }
    .margin({ bottom: this.bottomHeight })
  }
}
