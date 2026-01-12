import { authStore, hdHttp, HdUser, logger, InstallTimeUtil, normalizeUser } from '@itcast/basic'
import { promptAction, router } from '@kit.ArkUI'
import { BusinessError } from '@kit.BasicServicesKit'

interface LoginParams {
  username: string
  password: string
  installTime: string
}

interface UpdateProfileParams {
  nickName?: string
}

@Component
export struct LoginComp {
  @State mobile: string = '123123@qq.com'
  @State code: string = '123456'
  @State isAgree: boolean = true
  @State loading: boolean = false
  @State pendingNickName: string = ''
  @StorageProp('topHeight') topHeight: number = 0

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>
    if (params && params.username) {
      this.mobile = params.username
    }
    if (params && params.nickName) {
      this.pendingNickName = params.nickName
    }
  }

  async login() {
    if (!this.isAgree) {
      promptAction.showToast({ message: '请先阅读并同意用户协议' })
      return
    }
    if (!this.mobile || !this.code) {
      promptAction.showToast({ message: '请输入账号和验证码' })
      return
    }

    this.loading = true
    try {
      // 获取/生成 installTime
      const installTime = await InstallTimeUtil.getAppInstallTime()

      // 登录接口
      // 注意: hdHttp.post 返回的是 Promise<HdResponse<T>>，实际数据在 res.data 中
      const res = await hdHttp.post<HdUser>('login', {
        username: this.mobile,
        password: this.code,
        installTime: installTime
      } as LoginParams, true) // silent=true, 手动处理错误
      
      let user = res.data
      
      // Fix: Immediately unwrap and normalize login response
      // This ensures we have a flat object with the token
      const rawLoginData = user as Object as Record<string, Object>
      if (rawLoginData['userInfo']) {
        const token = user.token || (rawLoginData['userInfo'] as HdUser).token
        user = rawLoginData['userInfo'] as HdUser
        user.token = token
      }
      user = normalizeUser(user)

      // Fix: Save user (with token) to authStore immediately
      // This is crucial so that the subsequent 'userInfo' request has the Authorization header
      await authStore.setUser(user)
      
      // 登录成功后，立即调用 userInfo 接口获取完整用户信息 (包含实名认证等详细资料)
      try {
        const userInfoRes = await hdHttp.get<HdUser>('userInfo')
        const fullUserInfo = userInfoRes.data
        if (fullUserInfo) {
          // 兼容后端可能返回 { userInfo: ... } 的结构
          let targetUser = fullUserInfo
          
          // Fix: Cast to Record to allow indexed access in ArkTS (via Object)
          const rawObj = fullUserInfo as Object as Record<string, Object>
          if (rawObj['userInfo']) {
             targetUser = rawObj['userInfo'] as HdUser
             // 确保 token 存在
             if (fullUserInfo.token) {
               targetUser.token = fullUserInfo.token
               targetUser.refreshToken = fullUserInfo.refreshToken
             }
          }

          // 合并数据
          if (!targetUser.token) {
            targetUser.token = user.token
            targetUser.refreshToken = user.refreshToken
          }
          user = targetUser
        }
        
        // Fix: Normalize user data (handle case sensitivity)
        user = normalizeUser(user)
        // Update store with full info
        await authStore.setUser(user)
        AppStorage.setOrCreate('user', user)

      } catch (e) {
        logger.error('LoginComp', 'Failed to fetch full user info', e)
        // 获取失败不阻断登录流程，但可能导致资料显示不全
      }

      // 如果有待更新的昵称 (刚注册回来)，尝试更新
      if (this.pendingNickName) {
         try {
           // 仅当用户昵称不存在时更新
           if (!user.nickName) {
             // 尝试调用接口更新 (只传 nickName)
             await hdHttp.post<null>('userInfo/profile', { nickName: this.pendingNickName } as UpdateProfileParams)
             user.nickName = this.pendingNickName
           }
         } catch (e) {
           logger.error('LoginComp', 'Failed to update nickname', e)
           // 即使更新失败，本地也可以先显示
           user.nickName = this.pendingNickName
         }
      }

      // 保存用户信息
      await authStore.setUser(user)
      AppStorage.setOrCreate('user', user)

      promptAction.showToast({ message: '登录成功' })
      router.replaceUrl({ url: 'pages/Index' })
    } catch (err) {
      const error = err as BusinessError
      this.loading = false
      logger.error('LoginComp', 'Login failed', JSON.stringify(error))
      
      const errorCode = error.code || 0
      const errorMsg = error.message || '未知错误'

      if (errorCode === 403) {
        AlertDialog.show({
          title: '提示',
          message: errorMsg.includes('满') ? '设备授权已满，请联系管理员' : errorMsg,
          confirm: {
            value: '知道了',
            action: () => {}
          }
        })
      } else {
        promptAction.showToast({ message: '登录失败: ' + errorMsg })
      }
    } finally {
      this.loading = false
    }
  }

  build() {
    Column() {
      // Logo area
      Image($r('app.media.startIcon'))
        .width(80)
        .height(80)
        .margin({ top: 100, bottom: 50 })
        .objectFit(ImageFit.Contain)

      // Input area
      Column({ space: 20 }) {
        TextInput({ placeholder: '请输入账号/手机号', text: $$this.mobile })
          .type(InputType.Normal)
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15 })

        TextInput({ placeholder: '请输入验证码/密码', text: $$this.code })
          .type(InputType.Password)
          .height(50)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .padding({ left: 15 })
          .showPasswordIcon(true)
      }
      .padding({ left: 30, right: 30 })

      // Agreement
      Row() {
        Checkbox({ name: 'agree', group: 'login' })
          .select(this.isAgree)
          .onChange((value: boolean) => {
            this.isAgree = value
          })
          .width(20)
          .height(20)
        Text(' 我已阅读并同意《用户协议》和《隐私政策》')
          .fontSize(12)
          .fontColor('#999999')
      }
      .margin({ top: 20 })
      .justifyContent(FlexAlign.Start)
      .width('100%')
      .padding({ left: 30 })

      // Login Button
      Button('登录')
        .width('85%')
        .height(50)
        .margin({ top: 40 })
        .onClick(() => {
          this.login()
        })
        .enabled(!this.loading)
        .type(ButtonType.Normal)
        .borderRadius(25)
        .backgroundColor('#007DFF')

      // Register / Forgot Password
      Row() {
        Text('注册账号')
          .fontColor('#007DFF')
          .onClick(() => {
            router.pushUrl({ url: 'pages/RegisterPage' })
          })
        Text(' | ')
          .fontColor('#999999')
        Text('忘记密码')
          .fontColor('#999999')
      }
      .margin({ top: 20 })

    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .padding({ top: this.topHeight })
  }
}
