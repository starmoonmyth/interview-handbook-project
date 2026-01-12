import { authStore, logger } from '@itcast/basic';
import { TabBarComp } from '../views/Index/TabBarComp';
import { themeManager } from '@itcast/basic';
import { emitter } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct Index {
  @State
  @Watch('onChangeIndex')
  activeIndex: number = 0

  aboutToAppear(): void {
    themeManager.initThemeSetting()
    authStore.initUser()
    emitter.on({ eventId: 10000 }, (e) => {
      logger.info('Index', 'Receive event 10000', JSON.stringify(e))
      if (e.data && e.data.activeIndex !== undefined) {
        this.activeIndex = e.data.activeIndex as number
      }
    })
  }

  onChangeIndex() {
    if (this.activeIndex === 3) themeManager.settingStatusBarWhite()
    else themeManager.settingStatusBarBlack()
  }

  onPageShow(): void {
    this.onChangeIndex()
    authStore.initUser() // 每次页面显示时确保用户数据是最新的
  }

  onPageHide(): void {
    this.onChangeIndex()
    themeManager.settingStatusBarBlack()
    this.backTimes = 0
  }

  backTimes: number = 0

  onBackPress(): boolean | void {
    this.backTimes++
    if (this.backTimes <= 1) {
      promptAction.showToast({ message: '再按一次将退出应用' })
    }
    if (this.backTimes >= 2) {
      const ctx = getContext() as common.UIAbilityContext
      ctx.terminateSelf()
    }


    return true
  }

  build() {
    Flex() {
      TabBarComp({ activeIndex: this.activeIndex })
    }
    .backgroundColor($r('app.color.white'))
  }
}