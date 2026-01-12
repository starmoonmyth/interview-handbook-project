import { preferences } from '@kit.ArkData'
import { router } from '@kit.ArkUI'

export interface HdUser {
  id: string
  username: string
  avatar: string
  token: string
  refreshToken: string
  nickName?: string
  totalTime?: number
  clockinNumbers?: number
  realName?: string
  studentNo?: string
  gender?: number // 0: Secret, 1: Male, 2: Female
}

/**
 * 归一化用户数据，解决字段大小写不一致问题
 * Normalize user data to handle case sensitivity issues (e.g. nickName vs nickname)
 */
export function normalizeUser(data: HdUser | Record<string, Object>): HdUser {
  const raw = data as Record<string, Object>
  // ArkTS 不支持对象展开运算符 {...obj}，直接使用断言修改引用，或手动拷贝
  const user = data as HdUser

  // Nickname
  if (!user.nickName && raw['nickname']) {
    user.nickName = raw['nickname'] as string
  }

  // RealName
  if (!user.realName && raw['realname']) {
    user.realName = raw['realname'] as string
  }

  // StudentNo
  if (!user.studentNo && raw['studentno']) {
    user.studentNo = raw['studentno'] as string
  }
  
  // Gender (some backends might return 'sex')
  if (user.gender === undefined && raw['sex'] !== undefined) {
    user.gender = raw['sex'] as number
  }

  return user
}

export const AUTH_STORE_KEY = 'authStore'

class AuthStore {
  store: preferences.Preferences | null = null

  getStore() {
    if (!this.store) {
      this.store = preferences.getPreferencesSync(getContext(), { name: AUTH_STORE_KEY })
    }
    return this.store
  }

  async setUser(user: HdUser) {
    AppStorage.setOrCreate('user', user)
    await this.getStore().put(AUTH_STORE_KEY, JSON.stringify(user))
    await this.getStore().flush()
  }

  async delUser() {
    AppStorage.setOrCreate('user', {})
    await this.getStore().put(AUTH_STORE_KEY, '{}')
    await this.getStore().flush()
  }

  initUser() {
    const json = this.getStore().getSync(AUTH_STORE_KEY, '{}') as string
    AppStorage.setOrCreate('user', JSON.parse(json))
  }

  getUser() {
    return AppStorage.get<HdUser>('user') || {} as HdUser
  }

  checkAuth(options: router.RouterOptions | Function) {
    if (this.getUser().token) {
      if (typeof options === 'function') {
        options()
      } else {
        router.pushUrl(options)
      }
    } else {
      if (typeof options === 'function') {
        router.pushUrl({
          url: 'pages/LoginPage',
        })
      } else {
        const params = options.params as Record<string, string> || {}
        params.return_path = options.url
        router.pushUrl({
          url: 'pages/LoginPage',
          params: params
        })
      }
    }
  }
}

export const authStore = new AuthStore()