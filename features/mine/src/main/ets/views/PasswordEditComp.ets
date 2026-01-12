import { authStore, hdHttp, HdLoadingDialog, HdNav, HdUser, logger } from '@itcast/basic/Index'
import { promptAction, router } from '@kit.ArkUI'

interface PasswordParams {
  oldPassword?: string
  newPassword?: string
}

@Component
export struct PasswordEditComp {
  @StorageProp('user')
  user: HdUser = {} as HdUser
  @State oldPassword: string = ''
  @State newPassword: string = ''
  @State confirmPassword: string = ''
  @State loading: boolean = false

  dialog: CustomDialogController = new CustomDialogController({
    builder: HdLoadingDialog({ message: '修改中...' }),
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  updatePassword() {
    if (!this.oldPassword) {
      promptAction.showToast({ message: '请输入旧密码' })
      return
    }
    if (!this.newPassword) {
      promptAction.showToast({ message: '请输入新密码' })
      return
    }
    if (this.newPassword !== this.confirmPassword) {
      promptAction.showToast({ message: '两次新密码输入不一致' })
      return
    }
    if (this.oldPassword === this.newPassword) {
      promptAction.showToast({ message: '新密码不能与旧密码相同' })
      return
    }

    this.loading = true
    this.dialog.open()

    // 假设后端接口为 POST userInfo/password
    // 参数: oldPassword, newPassword
    hdHttp.post<null>('userInfo/password', {
      oldPassword: this.oldPassword,
      newPassword: this.newPassword
    } as PasswordParams).then(() => {
      promptAction.showToast({ message: '密码修改成功，请重新登录' })
      // 清除登录状态并跳转回登录页
      setTimeout(async () => {
        await authStore.delUser()
        router.clear()
        router.replaceUrl({
          url: 'pages/LoginPage'
        })
      }, 1500)
    }).catch((err: Error) => {
      promptAction.showToast({ message: '修改失败: ' + err.message })
    }).finally(() => {
      this.loading = false
      this.dialog.close()
    })
  }

  build() {
    Column() {
      HdNav({ title: '修改密码', showRightIcon: false })
      
      Column({ space: 20 }) {
        TextInput({ placeholder: '请输入旧密码', text: $$this.oldPassword })
          .type(InputType.Password)
          .showPasswordIcon(true)
          .customStyle()

        TextInput({ placeholder: '请输入新密码', text: $$this.newPassword })
          .type(InputType.Password)
          .showPasswordIcon(true)
          .customStyle()

        TextInput({ placeholder: '确认新密码', text: $$this.confirmPassword })
          .type(InputType.Password)
          .showPasswordIcon(true)
          .customStyle()

        Button({ type: ButtonType.Normal }) {
          Row() {
            if (this.loading) {
              LoadingProgress()
                .color($r('app.color.white'))
                .width(24)
                .height(24)
                .margin({ right: 10 })
            }
            Text('确认修改').fontColor($r('app.color.white'))
          }
        }
        .width('100%')
        .backgroundColor('none')
        .borderRadius(4)
        .height(44)
        .linearGradient({
          direction: GradientDirection.Right,
          colors: [['#fc9c1c', 0], ['#fa711d', 1]]
        })
        .margin({ top: 20 })
        .onClick(() => {
          this.updatePassword()
        })
      }
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }
}

@Extend(TextInput)
function customStyle() {
  .placeholderColor('#C3C3C5')
  .caretColor('#fa711d')
  .height(50)
  .borderRadius(0)
  .backgroundColor($r('app.color.white'))
  .border({ width: { bottom: $r('app.float.common_border_width') }, color: $r('app.color.common_gray_border') })
}
