import { hdHttp } from '@itcast/basic'
import { promptAction, router } from '@kit.ArkUI'

interface RegisterParams {
  username: string
  password: string
  role: 'STUDENT'
  nickName?: string
}

@Component
export struct RegisterComp {
  @State username: string = ''
  @State nickName: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State loading: boolean = false
  @StorageProp('topHeight') topHeight: number = 0

  register() {
    if (this.loading) return
    if (!this.username) {
      return promptAction.showToast({ message: '请输入用户名' })
    }
    if (!this.password) {
      return promptAction.showToast({ message: '请输入密码' })
    }
    if (this.password !== this.confirmPassword) {
      return promptAction.showToast({ message: '两次密码输入不一致' })
    }
    
    this.loading = true
    hdHttp.post<string>('register', {
      username: this.username,
      password: this.password,
      role: 'STUDENT',
      nickName: this.nickName
    } as RegisterParams).then(() => {
      promptAction.showToast({ message: '注册成功，请登录' })
      setTimeout(() => {
        // 跳转回登录页，并带回用户名和昵称
        router.back({
          url: 'pages/LoginPage',
          params: { username: this.username, nickName: this.nickName }
        })
      }, 1000)
    }).catch((err: Error) => {
      promptAction.showToast({ message: '注册失败: ' + err.message })
    }).finally(() => {
      this.loading = false
    })
  }

  build() {
    Navigation() {
      Column() {
        // Logo 区域
        Column() {
          Image($r('app.media.icon'))
            .width(100)
            .aspectRatio(1)
            .margin({ top: 40, bottom: 20 })
          Text('账号注册')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 40 })
        }

        // 表单区域
        Column({ space: 15 }) {
          TextInput({ placeholder: '请输入用户名', text: $$this.username })
            .customStyle()

          TextInput({ placeholder: '请输入昵称', text: $$this.nickName })
            .customStyle()
          
          TextInput({ placeholder: '请输入密码', text: $$this.password })
            .type(InputType.Password)
            .showPasswordIcon(true)
            .customStyle()

          TextInput({ placeholder: '确认密码', text: $$this.confirmPassword })
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
              Text('注册').fontColor($r('app.color.white'))
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
            this.register()
          })

          Row() {
             Text('已有账号？')
               .fontSize(14)
               .fontColor($r('app.color.common_gray_01'))
             Text('去登录')
               .fontSize(14)
               .fontColor('#fa711d')
               .onClick(() => {
                 router.back()
               })
          }
          .margin({ top: 16 })
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
    }
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .margin({ top: this.topHeight })
  }
}

@Extend(TextInput)
function customStyle() {
  .placeholderColor('#C3C3C5')
  .caretColor('#fa711d')
  .height(44)
  .borderRadius(0)
  .backgroundColor($r('app.color.white'))
  .border({ width: { bottom: $r('app.float.common_border_width') }, color: $r('app.color.common_gray_border') })
}
