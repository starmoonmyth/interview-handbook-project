import { http } from '@kit.NetworkKit';
import { authStore } from './auth';
import { promptAction, router } from '@kit.ArkUI';
import { BusinessError } from '@ohos.base';
import { logger } from './logger';
import { NetworkConfig } from '../constants/NetworkConfig';

interface HdRequestOptions {
  baseURL?: string
}

type HdParams = Record<string, string | number | boolean>

export interface HdResponse<T> {
  code: number
  message: string
  data: T
}

class HdHttp {
  baseURL: string

  constructor(options: HdRequestOptions) {
    this.baseURL = options.baseURL || ''
  }

  private request<T>(path: string, method: http.RequestMethod = http.RequestMethod.GET, extraData?: Object, silent: boolean = false) {
    const httpInstance = http.createHttp()

    const options: http.HttpRequestOptions = {
      header: {
        'Content-Type': 'application/json'
      },
      method,
      expectDataType: http.HttpDataType.OBJECT
    }

    let fullUrl = this.baseURL + path

    if (method === http.RequestMethod.GET && extraData) {
      const strArr = Object.keys(extraData)
        .filter(key => (extraData as HdParams)[key] !== undefined)
        .map(key => `${key}=${(extraData as HdParams)[key]}`)
      fullUrl += `?${strArr.join('&')}`
    } else {
      options.extraData = extraData
    }

    // 打印请求参数，方便调试
    logger.info(fullUrl, `Request Params: ${JSON.stringify(extraData || {})}`)

    const user = authStore.getUser()
    if (user.token && options.header) {
      options.header['Authorization'] = user.token
      // logger.info('Http', `Request ${path} with token`)
    }

    return httpInstance.request(fullUrl, options).then((res) => {
      if (res.result) {
        const result = res.result as HdResponse<T>
        if (result.code === 10000) {
          logger.info(fullUrl, JSON.stringify(res.result).substring(0, 200))
          return result
        }
        if (result.code === 401) {
          authStore.delUser()
          router.pushUrl({
            url: 'pages/LoginPage'
          }, router.RouterMode.Single)
          throw new Error('登录过期')
        }
      }
      return Promise.reject(res.result)
    }).catch((err: BusinessError) => {
      let message = err.message || '网络请求失败'
      if (err.message && err.message.includes('JSON')) {
        message = '后台返回数据格式错误 (非JSON)'
      }
      logger.error(fullUrl, err.code?.toString(), message)
      if (!silent) {
        promptAction.showToast({ message: message })
      }
      return Promise.reject(err)
    }).finally(() => {
      httpInstance.destroy()
    })
  }

  get<T>(url: string, data?: Object, silent: boolean = false): Promise<HdResponse<T>> {
    return this.request<T>(url, http.RequestMethod.GET, data, silent)
  }

  post<T>(url: string, data?: Object, silent: boolean = false): Promise<HdResponse<T>> {
    return this.request<T>(url, http.RequestMethod.POST, data, silent)
  }

  put<T>(url: string, data?: Object, silent: boolean = false): Promise<HdResponse<T>> {
    return this.request<T>(url, http.RequestMethod.PUT, data, silent)
  }

  delete<T>(url: string, data?: Object, silent: boolean = false): Promise<HdResponse<T>> {
    return this.request<T>(url, http.RequestMethod.DELETE, data, silent)
  }
}


export const hdHttp = new HdHttp({ baseURL: NetworkConfig.BASE_URL })