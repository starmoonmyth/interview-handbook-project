import { bundleManager } from '@kit.AbilityKit'
import { dbHelper } from './DbHelper'
import { logger } from './logger'
import { util } from '@kit.ArkTS' // 引入 util 模块用于格式化时间

const INSTALL_TIME_KEY = 'install_time'

export class InstallTimeUtil {
  /**
   * 获取 APP 安装时间 (格式化为 YYYY-MM-DD HH:mm:ss)
   * 逻辑：
   * 1. 检查本地 SQLite 数据库是否有记录
   * 2. 如果有，直接返回
   * 3. 如果没有，获取系统 BundleInfo 中的 installTime (时间戳)
   * 4. 格式化时间戳为可读字符串
   * 5. 存入 SQLite 并返回
   */
  static async getAppInstallTime(): Promise<string> {
    // 确保数据库已初始化
    await dbHelper.init(getContext())

    // 1. 尝试从数据库获取
    const cachedTime = await dbHelper.getValue(INSTALL_TIME_KEY)
    if (cachedTime) {
      logger.info('InstallTimeUtil', `Found cached install time: ${cachedTime}`)
      return cachedTime
    }

    // 2. 从系统获取
    let installTimeStr = ''
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      )
      // installTime 是 number (毫秒时间戳)
      if (bundleInfo.installTime > 0) {
        // 格式化时间戳
        const date = new Date(bundleInfo.installTime)
        installTimeStr = InstallTimeUtil.formatDate(date)
        logger.info('InstallTimeUtil', `Got system install time: ${installTimeStr}`)
      }
    } catch (err) {
      logger.error('InstallTimeUtil', `Failed to get bundle info: ${JSON.stringify(err)}`)
    }

    // 3. 如果获取不到系统安装时间，抛出错误
    if (!installTimeStr) {
      logger.error('InstallTimeUtil', 'Failed to retrieve valid install time from system')
      throw new Error('无法获取应用安装时间，请检查权限或系统状态')
    }

    // 4. 存入数据库
    await dbHelper.setValue(INSTALL_TIME_KEY, installTimeStr)
    
    return installTimeStr
  }

  // 辅助方法：格式化日期为 YYYY-MM-DD HH:mm:ss
  private static formatDate(date: Date): string {
    const pad = (n: number) => n.toString().padStart(2, '0')
    const year = date.getFullYear()
    const month = pad(date.getMonth() + 1)
    const day = pad(date.getDate())
    const hours = pad(date.getHours())
    const minutes = pad(date.getMinutes())
    const seconds = pad(date.getSeconds())
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`
  }
}
