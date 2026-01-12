import { authStore, hdHttp, HdLoadingDialog, HdNav, HdUser, logger, normalizeUser } from '@itcast/basic/Index'
import { promptAction } from '@kit.ArkUI'
import { fileIo, picker } from '@kit.CoreFileKit'
import { request } from '@kit.BasicServicesKit'

@Component
export struct ProfileEditComp {
  @StorageProp('user')
  user: HdUser = {} as HdUser
  dialog: CustomDialogController = new CustomDialogController({
    builder: HdLoadingDialog({ message: '更新中...' }),
    customStyle: true,
    alignment: DialogAlignment.Center
  })

  @State
  isRealNameLocked: boolean = false
  @State
  isGenderLocked: boolean = false
  @State
  currentGender: number = 0

  aboutToAppear(): void {
    logger.info('ProfileEditComp', `User Info: ${JSON.stringify(this.user)}`)
    // 初始化本地性别状态
    this.currentGender = this.user.gender || 0
    
    // 初始化锁定状态：只要有学号且对应字段有值，就视为已锁定（不可修改）
    // 注意：这里使用 State 变量是为了防止在编辑过程中因数据变化导致 UI 立即锁定（如性别）
    if (this.user.studentNo) {
      this.isRealNameLocked = !!this.user.realName
      // 只有当性别为有效值(1或2)时才锁定
      this.isGenderLocked = this.user.gender === 1 || this.user.gender === 2
    }
  }

  updateAvatar() {
    const photoSelectOptions = new picker.PhotoSelectOptions()
    photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE
    photoSelectOptions.maxSelectNumber = 1

    const photoViewPicker = new picker.PhotoViewPicker()
    photoViewPicker.select(photoSelectOptions).then(result => {
      // 1. 得到文件路径
      const URI = result.photoUris[0]
      // 2. 存储到沙箱中
      const context = getContext(this)
      const fileType = 'jpg'
      const fileName = Date.now() + '.' + fileType
      const copyFilePath = context.cacheDir + '/' + fileName
      const file = fileIo.openSync(URI, fileIo.OpenMode.READ_ONLY)
      fileIo.copyFileSync(file.fd, copyFilePath)
      // 3. 准备请求配置
      const config: request.UploadConfig = {
        url: hdHttp.baseURL + 'userInfo/avatar',
        method: 'POST',
        header: {
          'Accept': '*/*',
          'Authorization': `Bearer ${this.user.token}`,
          'Content-Type': 'multipart/form-data'
        },
        files: [
          { name: 'file', uri: `internal://cache/` + fileName, type: fileType, filename: fileName }
        ],
        data: []
      }
      // 4. 开始上传
      this.dialog.open()
      request.uploadFile(context, config, (err, data) => {
        if (err) {
          logger.error('UPLOAD', err.message)
          this.dialog.close()
          return promptAction.showToast({ message: '上传启动失败' })
        }
        data.on('complete', () => {
          // 5. 更新头像
          hdHttp.get<HdUser>('userInfo').then(res => {
            let data = res.data
            // Fix: Cast to Record to allow indexed access (via Object)
            const rawData = data as Object as Record<string, Object>
            if (rawData['userInfo']) {
              data = rawData['userInfo'] as HdUser
            }
            // Fix: Normalize user data
            data = normalizeUser(data)
            this.user.avatar = data.avatar
            authStore.setUser(this.user)
            promptAction.showToast({ message: '更新头像成功' })
          }).catch((err: Error) => {
            promptAction.showToast({ message: '更新头像失败: ' + err.message })
          }).finally(() => {
            this.dialog.close()
          })
        })
        data.on('fail', () => {
          this.dialog.close()
          promptAction.showToast({ message: '上传失败' })
        })
      })
    })
  }

  updateProfileInfo() {
    if (!this.user.realName) {
      promptAction.showToast({ message: '请填写真实姓名' })
      return
    }
    
    // 自动生成学号逻辑
    if (!this.user.studentNo) {
       const year = new Date().getFullYear()
       const random = Math.floor(Math.random() * 1000000).toString().padStart(6, '0')
       this.user.studentNo = `${year}${random}`
    }

    const postData: HdUser = {
      nickName: this.user.nickName,
      realName: this.user.realName,
      studentNo: this.user.studentNo,
      gender: this.currentGender
    } as HdUser
    
    logger.info('ProfileEditComp', `Submitting profile update: ${JSON.stringify(postData)}`)

    hdHttp.post<null>('userInfo/profile', postData).then(() => {
      // 重新获取用户信息以确保数据同步和正确持久化
      return hdHttp.get<HdUser>('userInfo')
    }).then(async (res) => {
      if (res.data) {
        let updatedUser = res.data
        // 兼容后端返回结构
        // Fix: Cast to Record to allow indexed access (via Object)
        const rawData = updatedUser as Object as Record<string, Object>
        if (rawData['userInfo']) {
           const token = updatedUser.token
           updatedUser = rawData['userInfo'] as HdUser
           if (token) updatedUser.token = token
        }
        
        // Fix: Normalize user data
        updatedUser = normalizeUser(updatedUser)

        // 保留 token，因为 userInfo 接口通常不返回 token
        if (this.user.token) {
          updatedUser.token = this.user.token
        }
        
        // 更新本地存储和状态
        await authStore.setUser(updatedUser)
        // 更新锁定状态
        this.isRealNameLocked = true
        this.isGenderLocked = true
        
        promptAction.showToast({ message: '资料更新成功' })
      }
    }).catch((err: Error) => {
      promptAction.showToast({ message: '更新失败: ' + err.message })
    })
  }

  // isProfileCompleted(): boolean {
  //   // 假设只要有学号就算认证过，或者可以根据 realName 判断
  //   // 后端逻辑：实名认证后 studentNo 和 realName 都会存在
  //   return !!(this.user.studentNo && this.user.realName)
  // }

  build() {
    Column() {
      HdNav({ title: '编辑资料', showRightIcon: false })
      List() {
        ListItem() {
          Row() {
            Text('头像')
            Image(this.user.avatar || $r('app.media.ic_mine_avatar'))
              .alt($r('app.media.ic_mine_avatar'))
              .width(40)
              .aspectRatio(1)
              .borderRadius(20)
              .border({ width: $r('app.float.common_border_width'), color: $r('app.color.common_gray_border') })
              .onClick(() => {
                this.updateAvatar()
              })
          }
          .width('100%')
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
        }

        ListItem() {
          Row() {
            Text('昵称')
            TextInput({ text: this.user.nickName })
              .fontColor($r('app.color.common_gray_03'))
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .padding(0)
              .height(60)
              .backgroundColor($r('app.color.white'))
              .borderRadius(0)
              .onChange((value) => this.user.nickName = value)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }

        ListItem() {
          Row() {
            Text('真实姓名')
            TextInput({ text: this.user.realName, placeholder: '填写真实姓名' })
              .fontColor($r('app.color.common_gray_03'))
              .textAlign(TextAlign.End)
              .layoutWeight(1)
              .padding(0)
              .height(60)
              .backgroundColor($r('app.color.white'))
              .borderRadius(0)
              .onChange((value) => this.user.realName = value)
              .enabled(!this.isRealNameLocked)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }

        ListItem() {
          Row() {
            Text('性别')
            Row() {
               Radio({ value: '1', group: 'gender' })
                 .checked(this.currentGender === 1)
                 .onChange((isChecked: boolean) => {
                   logger.info('ProfileEditComp', `Radio 1 changed: ${isChecked}`)
                   if(isChecked) this.currentGender = 1
                 })
                 .enabled(true)
                 .hitTestBehavior(this.isGenderLocked ? HitTestMode.None : HitTestMode.Default)
                 .radioStyle({
                   checkedBackgroundColor: this.isGenderLocked ? $r('app.color.common_blue') : undefined
                 })
                 .opacity(this.isGenderLocked && this.currentGender !== 1 ? 0.5 : 1)
               Text('男').margin({ right: 20 })
               
               Radio({ value: '2', group: 'gender' })
                 .checked(this.currentGender === 2)
                 .onChange((isChecked: boolean) => {
                   logger.info('ProfileEditComp', `Radio 2 changed: ${isChecked}`)
                   if(isChecked) this.currentGender = 2
                 })
                 .enabled(true)
                 .hitTestBehavior(this.isGenderLocked ? HitTestMode.None : HitTestMode.Default)
                 .radioStyle({
                   checkedBackgroundColor: this.isGenderLocked ? $r('app.color.common_blue') : undefined
                 })
                 .opacity(this.isGenderLocked && this.currentGender !== 2 ? 0.5 : 1)
               Text('女')
            }
          }
          .width('100%')
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
        }

        ListItem() {
          Row() {
            Text('学号')
            Text(this.user.studentNo || '自动生成')
              .fontColor($r('app.color.common_gray_03'))
          }
          .width('100%')
          .height(60)
          .justifyContent(FlexAlign.SpaceBetween)
        }

        ListItem() {
          Button('保存并实名')
            .width('100%')
            .height(44)
            .margin({ top: 20 })
            .onClick(() => {
              this.updateProfileInfo()
            })
        }
      }
      .width('100%')
      .height('100%')
      .padding({
        left: 35,
        right: 35,
        top: 15,
        bottom: 15
      })
      .divider({ strokeWidth: $r('app.float.common_border_width'), color: $r('app.color.common_gray_bg') })
    }
  }
}