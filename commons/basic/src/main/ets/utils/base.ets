import { preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'

export const getTimeText = (time: number = 0, hasUnit = true) => {
  if (time < 3600) {
    return String(Math.floor(time / 60)) + (hasUnit ? ' 分钟' : '')
  } else {
    return String(Math.round(time / 3600 * 10) / 10) + (hasUnit ? ' 小时' : '')
  }
}

export const getPercentText =
  (value: number, total: number) => Math.round(value / total * 100) + '%'

/**
 * 获取或生成设备唯一标识 (模拟 MAC 地址)
 * 优先从持久化存储中读取，如果没有则生成一个 UUID 并保存
 */
export const getDeviceId = (): string => {
  try {
    const store = preferences.getPreferencesSync(getContext(), { name: 'device_store' })
    let deviceId = store.getSync('mac_address', '') as string
    if (!deviceId) {
      // 生成 UUID 模拟 MAC 地址
      deviceId = util.generateRandomUUID(true)
      store.putSync('mac_address', deviceId)
      store.flush()
    }
    return deviceId
  } catch (e) {
    return '00:00:00:00:00:00' // Fallback
  }
}
